from __future__ import annotations

import hashlib
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass, field
from functools import reduce
from itertools import accumulate, islice, repeat
from operator import mul
from pathlib import Path
from struct import pack, unpack


class VerificationError(Exception):
    """Invalid proof."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerificationError(message)


# Field arithmetic ------------------------------------------------------------


def _base_mul(left: int, right: int) -> int:
    product = 0
    while right:
        if right & 1:
            product ^= left
        right >>= 1
        left <<= 1
    low, high = product & (2**64 - 1), product >> 64
    folded = low ^ high ^ (high << 1) ^ (high << 3) ^ (high << 4)
    overflow = folded >> 64
    return ((folded & (2**64 - 1)) ^ overflow ^ (overflow << 1) ^ (overflow << 3) ^ (overflow << 4)) & (2**64 - 1)


@dataclass(frozen=True, slots=True)
class K:
    """GF(2^64) = F2[x]/(x^64 + x^4 + x^3 + x + 1)"""

    value: int = 0

    def __post_init__(self) -> None:
        if not isinstance(self.value, int) or isinstance(self.value, bool) or not 0 <= self.value <= (2**64 - 1):
            raise ValueError("a K element is a 64-bit unsigned integer")

    def __index__(self) -> int:
        return self.value

    def to_bytes(self) -> bytes:
        """Its transport image: one 64-bit little-endian word."""
        return self.value.to_bytes(8, "little")

    def __bool__(self) -> bool:
        return bool(self.value)

    def __eq__(self, other: object) -> bool:
        if isinstance(other, K):
            return self.value == other.value
        return isinstance(other, int) and not isinstance(other, bool) and self.value == other

    def __hash__(self) -> int:
        return hash(self.value)

    def __add__(self, other: object) -> K:
        rhs = _as_k(other)
        return NotImplemented if rhs is None else K(self.value ^ rhs.value)

    __radd__ = __add__

    def __mul__(self, other: object) -> K:
        rhs = _as_k(other)
        return NotImplemented if rhs is None else K(_base_mul(self.value, rhs.value))

    __rmul__ = __mul__

    def __repr__(self) -> str:
        return f"K(0x{self.value:016x})"


def _as_k(value: object) -> K | None:
    if isinstance(value, K):
        return value
    if isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= 2**64 - 1:
        return K(value)
    return None


@dataclass(frozen=True, slots=True, init=False)
class E:
    """K[y]/(y^3 + y + 1): the challenge field, a degree-3 extension of K. Limbs may be given as plain integers, which are lifted."""

    c0: K
    c1: K
    c2: K

    def __init__(self, c0: K | int = 0, c1: K | int = 0, c2: K | int = 0) -> None:
        object.__setattr__(self, "c0", c0 if isinstance(c0, K) else K(c0))
        object.__setattr__(self, "c1", c1 if isinstance(c1, K) else K(c1))
        object.__setattr__(self, "c2", c2 if isinstance(c2, K) else K(c2))

    @classmethod
    def from_bytes(cls, data: bytes) -> E:
        require(len(data) == 24, "a field element must contain exactly 24 bytes")
        return cls(*unpack("<3Q", data))

    def to_bytes(self) -> bytes:
        return pack("<3Q", self.c0, self.c1, self.c2)

    @staticmethod
    def lift(value: object) -> E:
        """`value` as an extension element; anything that is not one is an error."""
        if isinstance(value, E):
            return value
        lifted = _as_k(value)
        if lifted is not None:
            return E(lifted)
        raise TypeError(f"cannot use {type(value).__name__} as a field element")

    @staticmethod
    def sum(values: Iterable[E]) -> E:
        return sum(values, ZERO)

    def __int__(self) -> int:
        return self.c0.value | self.c1.value << 64 | self.c2.value << 128

    def __bool__(self) -> bool:
        return bool(self.c0 or self.c1 or self.c2)

    def __eq__(self, other: object) -> bool:
        if isinstance(other, E):
            return self.c0 == other.c0 and self.c1 == other.c1 and self.c2 == other.c2
        return not (self.c1 or self.c2) and self.c0 == other

    def __hash__(self) -> int:
        return hash(int(self))

    def __add__(self, other: object) -> E:
        rhs = self.lift(other)
        return E(self.c0 + rhs.c0, self.c1 + rhs.c1, self.c2 + rhs.c2)

    __radd__ = __add__

    def __mul__(self, other: object) -> E:
        rhs = self.lift(other)
        # y^3 = y + 1 folds the degree-4 product back into three limbs.
        p0 = self.c0 * rhs.c0
        p1 = self.c0 * rhs.c1 + self.c1 * rhs.c0
        p2 = self.c0 * rhs.c2 + self.c1 * rhs.c1 + self.c2 * rhs.c0
        p3 = self.c1 * rhs.c2 + self.c2 * rhs.c1
        p4 = self.c2 * rhs.c2
        return E(p0 + p3, p1 + p3 + p4, p2 + p4)

    __rmul__ = __mul__

    def __pow__(self, exponent: int) -> E:
        if exponent < 0:
            return self.inv() ** -exponent
        base, out, n = self, ONE, exponent
        while n:
            if n & 1:
                out = out * base
            base = base * base
            n >>= 1
        return out

    def inv(self) -> E:
        require(bool(self), "division by zero in GF(2^192)")
        return self ** (2**192 - 2)

    def __truediv__(self, other: object) -> E:
        rhs = self.lift(other)
        return self * rhs.inv()

    def __repr__(self) -> str:
        return f"E(0x{self.c2.value:016x}{self.c1.value:016x}{self.c0.value:016x})"


ZERO = E(0)
ONE = E(1)
GEN = E(2)


def powers(base: E, count: int) -> list[E]:
    """`[1, base, base^2, ...]`, `count` terms."""
    return list(islice(accumulate(repeat(base), mul, initial=ONE), count))


# BLAKE2s and digests ---------------------------------------------------------

BLAKE2S_IV = (0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19)  # fmt: skip
BLAKE2S_SIGMA = ((0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15), (14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3), (11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4), (7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8), (9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13), (2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9), (12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11), (13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10), (6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5), (10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0))  # fmt: skip
BLAKE2S_G_LANES = ((0, 4, 8, 12), (1, 5, 9, 13), (2, 6, 10, 14), (3, 7, 11, 15), (0, 5, 10, 15), (1, 6, 11, 12), (2, 7, 8, 13), (3, 4, 9, 14))  # fmt: skip


def blake2s_hash(data: bytes) -> Digest:
    """Standard 32-byte unkeyed BLAKE2s-256 hash."""
    return Digest(hashlib.blake2s(data).digest())


@dataclass(frozen=True, slots=True)
class Digest:
    """256 bits"""

    value: bytes

    def __post_init__(self) -> None:
        require(len(self.value) == 32, "a digest is 256 bits")

    def words(self) -> tuple[int, int, int, int]:
        """Its four 64-bit words, the form the compression chain runs in."""
        return unpack("<4Q", self.value)

    def halves(self) -> tuple[E, E]:
        """Its two 128-bit halves, the one form a digest travels in."""
        w0, w1, w2, w3 = self.words()
        return (E(w0, w1), E(w2, w3))

    @classmethod
    def from_halves(cls, low: E, high: E) -> Digest:
        require(not (low.c2 or high.c2), "a digest half is 128-bit")
        return cls(pack("<4Q", low.c0, low.c1, high.c0, high.c1))


# Multilinear and stacking helpers --------------------------------------------


type MultilinearPoint = tuple[E, ...]


def eq_kernel(point: Sequence[E]) -> list[E]:
    out = [ONE]
    for r in point:
        out = [v * (ONE + r) for v in out] + [v * r for v in out]
    return out


def multilinear_eval(mle: Sequence[K | E], point: Sequence[E]) -> E:
    require(len(mle) == 2 ** len(point), "multilinear table has the wrong size")
    cur = [E.lift(value) for value in mle]
    for r in point:
        cur = [cur[2 * i] * (ONE + r) + cur[2 * i + 1] * r for i in range(len(cur) // 2)]
    return cur[0]


def log2_ceil(value: int) -> int:
    return max(0, (value - 1).bit_length())


def log2_strict(value: int) -> int:
    require(value > 0 and not value & (value - 1), "expected a power of two")
    return value.bit_length() - 1


def eq_eval(left: Sequence[E], right: Sequence[E]) -> E:
    result = ONE
    for x, y in zip(left, right, strict=True):
        result *= ONE + x + y
    return result


def dot(left: Sequence[K | E], right: Sequence[K | E]) -> E:
    result = ZERO
    for x, y in zip(left, right, strict=True):
        result += E.lift(x) * y
    return result


def index_mle(point: MultilinearPoint) -> E:
    """MLE of ``[1, g, g^2, ...]`` at an LSB-first point."""
    result = ONE
    generator_power = GEN
    for challenge in point:
        result *= ONE + challenge * (ONE + generator_power)
        generator_power **= 2
    return result


def poly_eval(coefficients: Sequence[E], point: E) -> E:
    """A polynomial at `point`, by Horner over its coefficients, constant first."""
    return reduce(lambda acc, c: acc * point + c, reversed(coefficients), ZERO)


@dataclass(frozen=True)
class Placement:
    """Where something sits in the stacked cube: a claim's point fills the `variables` coordinates above `low`, the bits of `index` fixing the rest.
    `low` is zero for a block with a cube of its own, and the slot width for a column interleaved into a bigger block."""

    variables: int
    index: int
    low: int = 0

    def stack_point(self, point: MultilinearPoint, stack_log: int) -> MultilinearPoint:
        bits = _selector_point(self.index, stack_log)
        return bits[: self.low] + tuple(point) + bits[self.low + self.variables :]

    def eq_above(self, point: Sequence[E]) -> E:
        """eq weight of the coordinates above the window."""
        bits = _selector_point(self.index >> (self.low + self.variables), len(point) - self.low - self.variables)
        return eq_eval(bits, point[self.low + self.variables :])


def stack_offsets(sizes: Sequence[int]) -> tuple[list[int], int]:
    offsets = [0] * len(sizes)
    total = 0
    for index, size in sorted(enumerate(sizes), key=lambda item: (-item[1], item[0])):
        offsets[index] = total
        total += 2**size
    return offsets, log2_ceil(total)


def _selector_point(selector: int, length: int) -> MultilinearPoint:
    return tuple(E(selector >> bit & 1) for bit in range(length))


# Proof transport ------------------------------------------------------------


@dataclass(frozen=True)
class Proof:
    stream: tuple[E, ...]
    merkle_openings: bytes

    @classmethod
    def load(cls, stream: Path, merkle_openings: Path) -> Proof:
        data = stream.read_bytes()
        require(len(data) % 24 == 0, "the stream is not a whole number of field elements")
        return cls(tuple(E.from_bytes(data[at : at + 24]) for at in range(0, len(data), 24)), merkle_openings.read_bytes())


# Fiat--Shamir ---------------------------------------------------------------

DS_OBSERVE = 1
DS_SQUEEZE = 2
DS_POW_BASE = 3
DS_POW_NONCE = 4


def compress(left: Sequence[K | int], right: Sequence[K | int]) -> tuple[int, int, int, int]:
    """Hash two four-word operands, a word being a plain integer or the K element standing for it."""
    return unpack("<4Q", blake2s_hash(b"".join(int(x).to_bytes(8, "little") for x in (*left, *right))).value)


class Transcript:
    def __init__(self, proof: Proof, fiat_shamir_IV: Digest, public_input: Digest) -> None:
        self.proof = proof
        self.state = compress(fiat_shamir_IV.words(), public_input.words())
        self.stream_offset = 0  # in E field elements
        self.opening_offset = 0  # in bytes

    def observe(self, value: E) -> None:
        self.state = compress(self.state, (value.c0, value.c1, value.c2, DS_OBSERVE))

    def sample(self) -> E:
        self.state = compress(self.state, (0, 0, 0, DS_SQUEEZE))
        return E(*self.state[:3])

    def samples(self, count: int) -> list[E]:
        return [self.sample() for _ in range(count)]

    def _next(self) -> E:
        require(self.stream_offset < len(self.proof.stream), "proof stream exhausted")
        value = self.proof.stream[self.stream_offset]
        self.stream_offset += 1
        return value

    def next_scalar(self) -> E:
        value = self._next()
        self.observe(value)
        return value

    def next_scalars(self, count: int) -> list[E]:
        return [self.next_scalar() for _ in range(count)]

    def grind_check(self, bits: int) -> None:
        nonce = self._next()
        block = (nonce.c0, nonce.c1, nonce.c2, DS_POW_NONCE)
        digest = compress(compress(self.state, (0, 0, 0, DS_POW_BASE)), block)[0]
        valid = nonce == ZERO if bits == 0 else digest & (2**bits - 1) == 0
        self.state = compress(self.state, block)
        require(valid, "invalid grinding nonce")

    def _merkle_data(self, length: int) -> bytes:
        end = self.opening_offset + length
        require(end <= len(self.proof.merkle_openings), "Merkle opening missing")
        chunk = self.proof.merkle_openings[self.opening_offset : end]
        self.opening_offset = end
        return chunk

    def merkle(self, root: Digest, block_length: int, queries: Sequence[int], leaf_words: int) -> list[tuple[K, ...]]:
        height = log2_strict(block_length)
        rows = []
        for query in queries:
            leaf = self._merkle_data(8 * leaf_words)
            node = blake2s_hash(leaf)
            for level in range(height):
                sibling = self._merkle_data(32)
                left, right = (node.value, sibling) if query >> level & 1 == 0 else (sibling, node.value)
                node = blake2s_hash(left + right)
            require(node == root, "Merkle root mismatch")
            rows.append(tuple(K(word) for word in unpack(f"<{leaf_words}Q", leaf)))
        return rows

    def sumcheck_round_poly(self, count: int, claim: E, eq_factor: E | None = None) -> list[E]:
        """returns q(X) := c0 + c1X + c2X^2 + ..."""
        if eq_factor is None:
            constant, tail = self.next_scalar(), self.next_scalars(count - 2)  # `q(0) + q(1) == claim`. The transcript contains c0, c2, c3 ...
            return [constant, claim + E.sum(tail), *tail]
        # `(1 + r) q(0) + r q(1) == claim`. The transcript contains c1, c2, c3 ... (r := eq_factor)
        tail = self.next_scalars(count - 1)
        return [claim + eq_factor * E.sum(tail), *tail]

    def finish(self) -> None:
        require(self.stream_offset == len(self.proof.stream), "proof stream not fully consumed")
        require(self.opening_offset == len(self.proof.merkle_openings), "Merkle openings not fully consumed")


def sumcheck(transcript: Transcript, claim: E, count: int, equalities: Sequence[E | None]) -> tuple[MultilinearPoint, E]:
    point = []
    for equality in equalities:
        message = transcript.sumcheck_round_poly(count, claim, equality)
        challenge = transcript.sample()
        point.append(challenge)
        claim = poly_eval(message, challenge)
    return tuple(point), claim


# Bus balance and decomposition ---------------------------------------------


def verify_gkr_grand_products(depth: int, transcript: Transcript) -> tuple[E, MultilinearPoint, tuple[E, E, E]]:
    shared, count = transcript.next_scalar(), transcript.next_scalar()
    point: list[E] = []
    values = (shared, shared, count)  # 3 grand product GKR are batched together: push, pull, count

    layer = depth
    while layer > 0:
        # Two levels a step. An odd depth starts with one.
        step = 1 if layer % 2 else 2
        combiner = transcript.sample()
        claim = poly_eval(values, combiner)
        # The product is degree 2^step, so one more coefficient than that per round.
        x, claim = sumcheck(transcript, claim, 2**step + 1, point)

        children = [transcript.next_scalars(2**step) for _ in range(3)]
        products = [reduce(mul, child) for child in children]
        require(claim == poly_eval(products, combiner), f"GKR layer {layer}: children do not match the sumcheck")

        y = transcript.samples(step)
        values = [multilinear_eval(child, y) for child in children]
        point = [*y, *x]
        layer -= step

    return count, tuple(point), (values[0], values[1], values[2])


@dataclass
class Form:
    """A polynomial of degree at most 2 in a table's columns."""

    terms: dict[tuple[int, ...], E] = field(default_factory=dict)  # monomial -> coefficient; () is 1, (i,) is x_i, (i, j) is x_i*x_j

    def add_scaled(self, other: Form, weight: E) -> None:
        for monomial, coefficient in other.terms.items():
            self.terms[monomial] = self.terms.get(monomial, ZERO) + weight * coefficient

    def __add__(self, other: Form) -> Form:
        combined = Form(dict(self.terms))
        combined.add_scaled(other, ONE)
        return combined

    @staticmethod
    def sum(forms: Iterable[Form]) -> Form:
        """`Σ forms`, the empty sum being the zero polynomial."""
        return sum(forms, Form())

    def evaluate(self, column: Callable[[int], E]) -> E:
        return E.sum(reduce(mul, map(column, monomial), c) for monomial, c in self.terms.items())


@dataclass(frozen=True)
class BusBlock:
    """One block of a bus side, always owned by a table. The three blocks no table owns are the framework, on `BusLayout`."""

    log_rows: int  # the owner's height: this block flushes 2^log_rows rows
    coordinates: tuple[Form, ...]  # the tuple flushed, over the owner's OWN local column indices; stays symbolic until its table sumcheck
    owner: int  # whose block it is, by opcode


@dataclass(frozen=True)
class BusLayout:
    """Where a side's blocks sit in the stacked leaf cube. Split by kind because framework coordinates are
    public, so the verifier evaluates their fingerprints outright, while a table's stay symbolic until its sumcheck."""

    depth: int  # log2 of the padded cube, so how many layers the side's GKR walks
    framework: tuple[Placement, ...]  # the blocks no table owns, stacked first: boundary state, memory, bytecode (none on the count side)
    tables: tuple[Placement, ...]  # one per block a table owns, in the side's own block order


FrameworkLogRows = tuple[int, int, int] | tuple[()]  # state, memory, bytecode


def bus_layout(framework_log_rows: FrameworkLogRows, blocks: Sequence[BusBlock]) -> BusLayout:
    sizes = [*framework_log_rows, *(block.log_rows for block in blocks)]
    offsets, depth = stack_offsets(sizes)
    placements = [Placement(size, offset) for size, offset in zip(sizes, offsets)]
    split = len(framework_log_rows)
    return BusLayout(depth, tuple(placements[:split]), tuple(placements[split:]))


@dataclass(frozen=True)
class ColumnClaim:
    column: int
    point: MultilinearPoint
    value: E

    def on_stack(self, layout: Layout) -> StackClaim:
        point = layout.placements[self.column].stack_point(self.point, layout.stack_log)
        return (lambda x: eq_eval(point, x), self.value)


BUS_BITS = 4  # bus communicates tuples of 2^BUS_BITS field elements


@dataclass(frozen=True)
class BusResult:
    claims: tuple[ColumnClaim, ...]
    point: MultilinearPoint  # the GKR point zeta, which the table sumcheck reuses
    forms: tuple[tuple[Form, ...], ...]  # forms[table][side]
    totals: tuple[E, E, E]  # what the tables owe each side, derived


def verify_bus_balance(layout: Layout, transcript: Transcript) -> BusResult:
    framework_log_rows = (0, layout.log_memory, layout.log_bytecode)  # state, memory, bytecode
    push_layout = bus_layout(framework_log_rows, layout.push)
    pull_layout = bus_layout(framework_log_rows, layout.pull)
    count_layout = bus_layout((), layout.count)

    alphas = transcript.samples(BUS_BITS)
    weights = eq_kernel(alphas)
    beta = transcript.sample()
    count_root, point, tree_values = verify_gkr_grand_products(push_layout.depth, transcript)
    require(count_root != ZERO, "a bus count is zero")

    # The framework blocks' committed columns, in the order the two sides first
    # name them: the memory image on push, then each array's final count on pull.
    memory_low = tuple(point[: layout.log_memory])
    bytecode_low = tuple(point[: layout.log_bytecode])
    memory = transcript.next_scalars(3)
    memory_final = transcript.next_scalar()
    bytecode_final = transcript.next_scalar()
    claims = [ColumnClaim(column, memory_low, memory[column]) for column in (MEMORY_0, MEMORY_1, MEMORY_2)]
    claims.append(ColumnClaim(MEMORY_FINAL_COUNTERS, memory_low, memory_final))
    claims.append(ColumnClaim(BYTECODE_FINAL_COUNTERS, bytecode_low, bytecode_final))
    memory_index = index_mle(memory_low)
    bytecode_index = index_mle(bytecode_low)
    bytecode_value = multilinear_eval(layout.bytecode, (*bytecode_low, *alphas))

    def fingerprints(pc: E, memory_count: E, bytecode_count: E) -> tuple[E, E, E]:
        """The three framework tuples, each its coordinates weighted by eq(alpha, .); slots past the ones
        named are zero. A side differs only here: push seeds each array at count one, pull finalizes it
        with the committed final count and ends at the last pc. Both boundaries sit in frame 0."""
        return (
            dot(weights[:3], (SEP_STATE, pc, _gpow(0))),
            dot(weights[:6], (SEP_MEM, memory_index, memory_count, *memory)),
            dot(weights[:3], (SEP_BYTECODE, bytecode_index, bytecode_count)) + bytecode_value,
        )

    final_pc = _gpow(2**layout.log_bytecode - 1)  # the execution ends at the bytecode's last instruction
    sides = (
        (layout.push, push_layout, fingerprints(_gpow(0), ONE, ONE), weights, beta),
        (layout.pull, pull_layout, fingerprints(final_pc, memory_final, bytecode_final), weights, beta),
        (layout.count, count_layout, (), (ONE,), ZERO),  # The count channel owns no framework block and runs at alpha = beta = 0.
    )
    totals = []  # what remains to be proven by the next table sumcheck
    forms = tuple(tuple(Form() for _ in range(3)) for _ in TABLES)
    for side, (blocks, side_layout, framework_fingerprints, side_weights, side_beta) in enumerate(sides):
        framework_selectors = [p.eq_above(point) for p in side_layout.framework]
        table_selectors = [p.eq_above(point) for p in side_layout.tables]
        known = dot(framework_selectors, [side_beta + fingerprint for fingerprint in framework_fingerprints])
        # A table's blocks stay symbolic: they accumulate into the form its sumcheck settles over its own columns.
        beta_form = _const(side_beta)
        for selector, block in zip(table_selectors, blocks, strict=True):
            form = forms[block.owner][side]
            form.add_scaled(beta_form, selector)
            for slot, coordinate in enumerate(block.coordinates):
                form.add_scaled(coordinate, selector * side_weights[slot])  # the fingerprint, one tuple slot at a time
        # Every occupied row holds beta + its fingerprint; the rest of the leaf cube holds 1.
        ones_padding = E.sum(framework_selectors + table_selectors) + ONE
        totals.append(tree_values[side] + known + ones_padding)  # what the forms owe: the GKR value, less framework and padding

    return BusResult(tuple(claims), point, forms, (totals[0], totals[1], totals[2]))


# Table sumcheck -------------------------------------------------------------


def table_sumcheck(
    table_log_heights: Sequence[int],
    bus_forms: Sequence[Sequence[Form]],
    constraint_powers: Sequence[E],
    form_powers: Sequence[E],
    equality_point: MultilinearPoint,
    target: E,
    transcript: Transcript,
) -> list[ColumnClaim]:
    n_rounds = max(table_log_heights)
    challenges, claim = sumcheck(transcript, target, 4, [None] * n_rounds)
    point = list(reversed(challenges))
    weights = [ONE] * len(TABLES)
    for variable, challenge in enumerate(point):
        equality = ONE + equality_point[variable] + challenge
        for index, height in enumerate(table_log_heights):
            weights[index] *= equality if height > variable else challenge

    final = ZERO
    cursor = 0
    claims: list[ColumnClaim] = []
    for table, height, forms, weight in zip(TABLES, table_log_heights, bus_forms, weights, strict=True):
        evaluations = tuple(transcript.next_scalars(table.width))
        summand = dot(constraint_powers[cursor : cursor + table.n_constraints], table.constraints(evaluations))
        final += weight * (summand + dot(form_powers, [form.evaluate(evaluations.__getitem__) for form in forms]))
        cursor += table.n_constraints
        table_point = tuple(point[:height])
        claims.extend(ColumnClaim(GLOBAL_COLUMN_BASES[table.opcode] + local, table_point, value) for local, value in enumerate(evaluations))
    require(final == claim, "table sumcheck terminal mismatch")
    return claims


R1CS_DIGEST = bytes.fromhex("537ad20790308f8eb8c0e8bd3e6c58ee64573371e3d53c30613dd04d87c0b7ea")

# The columns no instruction table owns. They come first in the global column numbering, the tables after.
NUM_GLOBAL_COLUMNS = 6
MEMORY_0, MEMORY_1, MEMORY_2, MEMORY_FINAL_COUNTERS, BYTECODE_FINAL_COUNTERS, QFLOCK = range(NUM_GLOBAL_COLUMNS)

BLAKE2S_R1CS_LOG_SIZE = 14
K_BITS = 64
FLOCK_K_SKIP = log2_ceil(K_BITS)
LOG_PACKING = log2_ceil(K_BITS)  # bits per committed K-element (pcs::pack::LOG_PACKING)

FLOCK_NUM_LINCHECK_ROUNDS = BLAKE2S_R1CS_LOG_SIZE - FLOCK_K_SKIP
QFLOCK_SLOT_BITS = BLAKE2S_R1CS_LOG_SIZE - LOG_PACKING
BLAKE2S_CONSTANT_COLUMN = 512


@dataclass(frozen=True)
class Layout:
    log_memory: int
    log_bytecode: int
    bytecode: Sequence[K]
    push: tuple[BusBlock, ...]
    pull: tuple[BusBlock, ...]
    count: tuple[BusBlock, ...]
    placements: tuple[Placement, ...]
    stack_log: int
    table_log_heights: tuple[int, ...]


def _cols(columns: Sequence[str], *names: str) -> tuple[int, ...]:
    assert set(names) <= set(columns), f"unknown columns: {sorted(set(names) - set(columns))}"
    return tuple(columns.index(name) for name in names)


def _gpow(index: int) -> E:
    return GEN**index


def _const(value: E | int) -> Form:
    return Form({(): value if isinstance(value, E) else E(value)})


def _col(index: int, exponent: int = 0) -> Form:
    return Form({(index,): _gpow(exponent)})


def _prod(a: int, b: int, exponent: int = 0) -> Form:
    return Form({tuple(sorted((a, b))): _gpow(exponent)})


SEP_STATE = ONE
SEP_MEM = GEN
SEP_BYTECODE = GEN**2


class Flushes:
    def __init__(self) -> None:
        self.push: list[tuple[Form, ...]] = []
        self.pull: list[tuple[Form, ...]] = []

    def pair(self, push: Sequence[Form], pull: Sequence[Form]) -> None:
        self.push.append(tuple(push))
        self.pull.append(tuple(pull))

    def state_derived(self, pc: int, fp: int, npc: Form, nfp: Form) -> None:
        self.pair((_const(SEP_STATE), npc, nfp), (_const(SEP_STATE), _col(pc), _col(fp)))

    def state_step(self, pc: int, fp: int) -> None:
        self.state_derived(pc, fp, _col(pc, 1), _col(fp))

    def _counted(self, prefix: Sequence[Form], count: int, suffix: Sequence[Form]) -> None:
        self.pair((*prefix, _col(count, 1), *suffix), (*prefix, _col(count), *suffix))

    def bytecode(self, pc: int, count: int, opcode: int, operands: Sequence[Form]) -> None:
        self._counted((_const(SEP_BYTECODE), _col(pc)), count, (_const(_gpow(opcode)), *operands))

    def memory(self, address: Form, count: int, values: Sequence[Form]) -> None:
        self._counted((_const(SEP_MEM), address), count, values)

    def memory_cols(self, address: Form, count: int, *columns: int) -> None:
        self.memory(address, count, [_col(column) for column in columns] + [_const(ZERO)] * (3 - len(columns)))


# The instruction tables ------------------------------------------------------


@dataclass(frozen=True)
class Table:
    """One instruction's table: its columns, its bus flushes, its constraints."""

    name: str
    opcode: int  # also its index in TABLES, so g^opcode is its bytecode tag
    columns: tuple[str, ...]
    flushes: Flushes
    constraints: Callable[[Sequence[E]], tuple[E, ...]] = lambda _: ()

    @property
    def n_constraints(self) -> int:
        return len(self.constraints([ZERO] * self.width))

    @property
    def width(self) -> int:
        return len(self.columns)

    @property
    def count_columns(self) -> tuple[int, ...]:
        return tuple(i for i, name in enumerate(self.columns) if name.startswith("cnt"))


def _flushes_arith(opcode: int, multiply: bool) -> Flushes:
    pc, fp, o_a, o_b, o_c, cnt_a, cnt_b, cnt_c, cnt_bc = _cols(ARITH_COLUMNS, "pc", "fp", "o_a", "o_b", "o_c", "cnt_a", "cnt_b", "cnt_c", "cnt_bc")
    va, vb = _cols(ARITH_COLUMNS, "va_0", "va_1", "va_2"), _cols(ARITH_COLUMNS, "vb_0", "vb_1", "vb_2")
    flushes = Flushes()
    flushes.state_step(pc, fp)
    flushes.bytecode(pc, cnt_bc, opcode, (_col(o_a), _col(o_b), _col(o_c), _const(ZERO), _const(ZERO)))
    flushes.memory_cols(_prod(fp, o_a), cnt_a, *va)
    flushes.memory_cols(_prod(fp, o_b), cnt_b, *vb)
    TOWER_LANES = (((0, 0), (1, 2), (2, 1)), ((0, 1), (1, 0), (1, 2), (2, 1), (2, 2)), ((0, 2), (1, 1), (2, 0), (2, 2)))
    result = (
        tuple(Form.sum(_prod(va[j], vb[k]) for j, k in lane) for lane in TOWER_LANES)
        if multiply
        else tuple(_col(va[i]) + _col(vb[i]) for i in range(3))
    )
    flushes.memory(_prod(fp, o_c), cnt_c, result)
    return flushes


def _flushes_set() -> Flushes:
    pc, fp, o, cnt, cnt_bc = _cols(SET_COLUMNS, "pc", "fp", "o", "cnt", "cnt_bc")
    k = _cols(SET_COLUMNS, "k_0", "k_1", "k_2")
    flushes = Flushes()
    flushes.state_step(pc, fp)
    flushes.bytecode(pc, cnt_bc, OP_SET, (_col(o), *(_col(limb) for limb in k), _const(ZERO)))
    flushes.memory_cols(_prod(fp, o), cnt, *k)
    return flushes


def _flushes_deref() -> Flushes:
    pc, fp, o1, o2, o3, f_pc, f_fp, ptr = _cols(DEREF_COLUMNS, "pc", "fp", "o1", "o2", "o3", "f_pc", "f_fp", "ptr")
    cnt_ptr, cnt_target, cnt_local, cnt_bc = _cols(DEREF_COLUMNS, "cnt_ptr", "cnt_target", "cnt_local", "cnt_bc")
    v3 = _cols(DEREF_COLUMNS, "v3_0", "v3_1", "v3_2")

    def gated(lane: int) -> list[Form]:
        return [_col(lane), _prod(f_pc, lane), _prod(f_fp, lane)]

    # v2 = (1 + f_pc + f_fp)*v3 + f_pc*(g^2*pc) + f_fp*fp, lane-wise: only the low lane takes the two K-valued sources.
    store = (Form.sum((*gated(v3[0]), _prod(f_pc, pc, 2), _prod(f_fp, fp))), Form.sum(gated(v3[1])), Form.sum(gated(v3[2])))
    flushes = Flushes()
    flushes.state_step(pc, fp)
    flushes.bytecode(pc, cnt_bc, OP_DEREF, (_col(o1), _col(o2), _col(o3), _col(f_pc), _col(f_fp)))
    flushes.memory_cols(_prod(fp, o1), cnt_ptr, ptr)
    flushes.memory(_prod(ptr, o2), cnt_target, store)
    flushes.memory_cols(_prod(fp, o3), cnt_local, *v3)
    return flushes


def _flushes_jump() -> Flushes:
    pc, fp, o_c, o_d, o_f, cond, dest, frame, b = _cols(JUMP_COLUMNS, "pc", "fp", "o_c", "o_d", "o_f", "v_cond", "v_pc", "v_fp", "b")
    cnt_c, cnt_d, cnt_f, cnt_bc = _cols(JUMP_COLUMNS, "cnt_c", "cnt_d", "cnt_f", "cnt_bc")
    flushes = Flushes()
    # next_pc = b*dest + (b+1)*g*pc, next_fp = b*frame + (b+1)*fp, both derived.
    flushes.state_derived(pc, fp, _prod(b, dest) + _prod(b, pc, 1) + _col(pc, 1), _prod(b, frame) + _prod(b, fp) + _col(fp))
    flushes.bytecode(pc, cnt_bc, OP_JUMP, (_col(o_c), _col(o_d), _col(o_f), _const(ZERO), _const(ZERO)))
    flushes.memory_cols(_prod(fp, o_c), cnt_c, cond)
    flushes.memory_cols(_prod(fp, o_d), cnt_d, dest)
    flushes.memory_cols(_prod(fp, o_f), cnt_f, frame)
    return flushes


def _jump_constraints(columns: Sequence[E]) -> tuple[E, ...]:
    condition, inverse, flag = (columns[index] for index in _cols(JUMP_COLUMNS, "v_cond", "w", "b"))
    return (flag + condition * inverse, condition * (flag + ONE))


def _flushes_blake2s() -> Flushes:
    pc, fp, cnt_bc = _cols(BLAKE2S_COLUMNS, "pc", "fp", "cnt_bc")
    operands = _cols(BLAKE2S_COLUMNS, "o_0", "o_1", "o_2", "o_3", "o_v", "o_out", "o_md")
    flushes = Flushes()
    flushes.state_step(pc, fp)
    flushes.bytecode(pc, cnt_bc, OP_BLAKE2S, tuple(_col(i) for i in operands))
    # The nine cells read, as (cell, operand, offset from it): four addressed message chunks, then
    # the consecutive chaining-value and output pairs, then the metadata cell (the byte counter and
    # the two flags). Each holds two q_flock limbs and a zero top.
    cells = (("m0", "o_0", 0), ("m1", "o_1", 0), ("m2", "o_2", 0), ("m3", "o_3", 0),
             ("cv0", "o_v", 0), ("cv1", "o_v", 1), ("out0", "o_out", 0), ("out1", "o_out", 1),
             ("md", "o_md", 0))  # fmt: skip
    for cell, operand, exponent in cells:
        address, count, lo, hi = _cols(BLAKE2S_COLUMNS, operand, f"cnt_{cell}", f"{cell}_lo", f"{cell}_hi")
        flushes.memory_cols(_prod(fp, address, exponent), count, lo, hi)
    return flushes


OP_XOR, OP_MUL, OP_SET, OP_DEREF, OP_JUMP, OP_BLAKE2S = range(6)

ARITH_COLUMNS = ("pc", "fp", "o_a", "o_b", "o_c", "va_0", "va_1", "va_2", "vb_0", "vb_1", "vb_2", "cnt_a", "cnt_b", "cnt_c", "cnt_bc",)  # fmt: skip
SET_COLUMNS = ("pc", "fp", "o", "k_0", "k_1", "k_2", "cnt", "cnt_bc")
DEREF_COLUMNS = ("pc", "fp", "o1", "o2", "o3", "f_pc", "f_fp", "ptr", "v3_0", "v3_1", "v3_2",  "cnt_ptr", "cnt_target", "cnt_local", "cnt_bc",)  # fmt: skip
JUMP_COLUMNS = ("pc", "fp", "o_c", "o_d", "o_f", "v_cond", "v_pc", "v_fp", "cnt_c", "cnt_d", "cnt_f", "cnt_bc", "w", "b",)  # fmt: skip
BLAKE2S_COLUMNS = (
    "pc", "fp", "o_0", "o_1", "o_2", "o_3", "o_v", "o_out", "o_md",
    # These eighteen value limbs live in q_flock, not here: each is already a flock witness slot.
    "m0_lo", "m0_hi", "m1_lo", "m1_hi", "m2_lo", "m2_hi", "m3_lo", "m3_hi",
    "out0_lo", "out0_hi", "out1_lo", "out1_hi", "cv0_lo", "cv0_hi", "cv1_lo", "cv1_hi", "md_lo", "md_hi",
    # ...and the read counts, committed here like every other column.
    "cnt_m0", "cnt_m1", "cnt_m2", "cnt_m3", "cnt_cv0", "cnt_cv1", "cnt_out0", "cnt_out1", "cnt_md", "cnt_bc",
)  # fmt: skip

TABLES = (
    Table("xor", OP_XOR, ARITH_COLUMNS, _flushes_arith(OP_XOR, multiply=False)),
    Table("mul", OP_MUL, ARITH_COLUMNS, _flushes_arith(OP_MUL, multiply=True)),
    Table("set", OP_SET, SET_COLUMNS, _flushes_set()),
    Table("deref", OP_DEREF, DEREF_COLUMNS, _flushes_deref()),
    Table("jump", OP_JUMP, JUMP_COLUMNS, _flushes_jump(), _jump_constraints),
    Table("blake2s", OP_BLAKE2S, BLAKE2S_COLUMNS, _flushes_blake2s()),
)

# Where in the flock witness each embedded BLAKE2s limb live: one 64-bit slot per limb, the chaining value first, then the
# digest, the message block and the metadata. Slots 8 and 9 are flock's constant wire and the padding up to its message base, which no memory cell carries.
BLAKE2S_SLOTS = (
    "cv0_lo", "cv0_hi", "cv1_lo", "cv1_hi", "out0_lo", "out0_hi", "out1_lo", "out1_hi", None, None,
    "m0_lo", "m0_hi", "m1_lo", "m1_hi", "m2_lo", "m2_hi", "m3_lo", "m3_hi", "md_lo", "md_hi",
)  # fmt: skip

TABLE_WIDTHS = tuple(t.width for t in TABLES)
GLOBAL_COLUMN_BASES = tuple(NUM_GLOBAL_COLUMNS + sum(TABLE_WIDTHS[:table]) for table in range(len(TABLES)))


def build_layout(bytecode: Sequence[K], log_memory: int, table_log_heights: Sequence[int]) -> Layout:
    log_bytecode = log2_strict(len(bytecode)) - BUS_BITS
    require(
        16 <= log_memory <= 32
        and all(0 <= log_height <= 32 for log_height in table_log_heights)
        and table_log_heights[OP_BLAKE2S] >= 3
        and 0 <= log_bytecode <= 32,
        "invalid announced table sizes",
    )

    push: list[BusBlock] = []
    pull: list[BusBlock] = []
    count: list[BusBlock] = []
    for table, height in zip(TABLES, table_log_heights, strict=True):
        flushes = table.flushes
        for coordinates in flushes.push:
            push.append(BusBlock(height, coordinates, table.opcode))
        for coordinates in flushes.pull:
            pull.append(BusBlock(height, coordinates, table.opcode))
        for local in table.count_columns:
            count.append(BusBlock(height, (_col(local),), table.opcode))

    # Every column's log size, in global order: the framework's, q_flock's, then each table's block.
    qflock_kappa = table_log_heights[OP_BLAKE2S] + QFLOCK_SLOT_BITS
    kappas = [log_memory, log_memory, log_memory, log_memory, log_bytecode, qflock_kappa]
    for table in TABLES:
        kappas += [table_log_heights[table.opcode]] * table.width

    # A BLAKE2s value limb gets no block of its own: it is committed inside q_flock, whose slots
    # interleave, so it sits at q_flock's offset behind its own slot's bits. Same width either way.
    limbs = {GLOBAL_COLUMN_BASES[OP_BLAKE2S] + _cols(BLAKE2S_COLUMNS, name)[0]: slot for slot, name in enumerate(BLAKE2S_SLOTS) if name}
    blocks = {column: kappa for column, kappa in enumerate(kappas) if column not in limbs}
    block_offsets, total_log = stack_offsets(list(blocks.values()))
    offsets = dict(zip(blocks, block_offsets))
    stack_log = max(MIN_STACKED_LOG, total_log)  # Floor at the PCS minimum
    placements = [
        Placement(kappa, offsets[QFLOCK] + limbs[column], QFLOCK_SLOT_BITS) if column in limbs else Placement(kappa, offsets[column])
        for column, kappa in enumerate(kappas)
    ]
    return Layout(log_memory, log_bytecode, bytecode, tuple(push), tuple(pull), tuple(count), tuple(placements), stack_log, tuple(table_log_heights))


# WHIR opening ----------------------------------------------------------------

INITIAL_FOLDING_FACTOR = 6
SUBSEQUENT_FOLDING_FACTOR = 4
RS_DOMAIN_INITIAL_REDUCTION_FACTOR = 3
RS_DOMAIN_SUBSEQUENT_REDUCTION_FACTOR = 1
RESIDUAL_MAX_LOG = 5
QUERY_GRINDING_BITS = 17

MIN_STACKED_LOG = 15
MAX_STACKED_LOG = 28

WHIR_QUERIES = (((222,55), (223,56,30), (223,56,31), (223,56,32), (223,56,32), (223,56,32,22), (223,56,32,22), (224,56,32,23), (224,56,32,23), (224,56,32,23,17), (224,56,32,23,17), (224,56,32,23,18), (225,56,32,23,18), (225,56,32,23,18,14)), ((111,45), (112,45,27), (112,45,28), (112,45,28), (112,45,28), (112,45,28,20), (112,45,28,20), (112,45,28,21), (112,45,28,21), (112,45,28,21,16), (112,45,28,21,16), (112,45,28,21,16), (112,45,28,21,16), (112,45,28,21,16,13)), ((75,37), (75,37,24), (75,37,25), (75,38,25), (75,38,25), (75,38,25,18), (75,38,25,19), (75,38,25,19), (75,38,25,19), (75,38,25,19,15), (75,38,25,19,15), (75,38,25,19,15), (75,38,25,19,15), (75,38,25,19,15,13)), ((56,32), (56,32,22), (56,32,22), (56,32,23), (56,32,23), (56,32,23,17), (56,32,23,17), (56,32,23,18), (56,32,23,18), (56,32,23,18,14), (56,32,23,18,14), (56,32,23,18,14), (56,32,23,18,15), (56,32,23,18,15,12)))  # fmt: skip


@dataclass(frozen=True)
class WhirConfig:
    log_inv_rates: tuple[int, ...]
    folds: tuple[int, ...]
    queries: tuple[int, ...]


def derive_config(log_n: int, log_inv_rate: int) -> WhirConfig:
    """The opening shape at this size and rate: the ladder geometry, then the
    tabulated query counts."""
    require(MIN_STACKED_LOG <= log_n <= MAX_STACKED_LOG and 1 <= log_inv_rate <= 4, "invalid WHIR shape")
    folds = [INITIAL_FOLDING_FACTOR]
    log_inv_rates = [log_inv_rate]
    remaining = log_n - INITIAL_FOLDING_FACTOR
    while remaining > RESIDUAL_MAX_LOG:
        first = len(folds) == 1
        log_inv_rates.append(log_inv_rates[-1] + folds[-1] - (RS_DOMAIN_INITIAL_REDUCTION_FACTOR if first else RS_DOMAIN_SUBSEQUENT_REDUCTION_FACTOR))
        fold = min(SUBSEQUENT_FOLDING_FACTOR, remaining)
        remaining -= fold
        folds.append(fold)
    queries = WHIR_QUERIES[log_inv_rate - 1][log_n - MIN_STACKED_LOG]
    require(len(queries) == len(folds), "tabulated query count does not match the ladder")
    return WhirConfig(log_inv_rates=tuple(log_inv_rates), folds=tuple(folds), queries=queries)


def _ext_row(words: Sequence[K]) -> tuple[E, ...]:
    """Regroup a level's leaf words into the E values they encode, three per lane."""
    return tuple(E(*words[i : i + 3]) for i in range(0, len(words), 3))


def sample_queries(transcript: Transcript, block_length: int, count: int) -> list[int]:
    depth = log2_strict(block_length)
    per_word = 192 // depth
    result: list[int] = []
    while len(result) < count:
        bits = int(transcript.sample())
        for chunk in range(min(per_word, count - len(result))):
            result.append((bits >> (chunk * depth)) & (block_length - 1))
    return result


def _enforced_sum(rows: Sequence[Sequence[K | E]], folds: Sequence[E], query_weights: Sequence[E]) -> E:
    lane_weights = eq_kernel(folds)
    total = ZERO
    for query_weight, row in zip(query_weights, rows, strict=True):
        total += query_weight * dot(row, lane_weights)
    return total


def _subspace_roots(log_n: int) -> list[E]:
    roots = [ONE]
    layer = [E(2**i) for i in range(1, log_n + 1)]
    for _ in range(log_n):
        layer = [value**2 + roots[-1] * value for value in layer]
        roots.append(layer.pop(0))
    return roots


def _induced_weight(message_log: int, queries: Sequence[int], query_weights: Sequence[E], point: Sequence[E]) -> E:
    """The level's batched query claims, as one weight at `point`.

    Each query contributes the novel-basis column weight of doc annex B, Lemma
    lem:colweight, `prod_k (1 + p_k (1 + W-hat_k(x_q)))`, scaled by its power of
    the level's batching challenge.
    """
    require(len(point) == message_log, "bad induced-basis dimensions")
    roots = _subspace_roots(message_log)
    inverses = [value.inv() if value else ZERO for value in roots]
    total = ZERO
    for weight, query in zip(query_weights, queries, strict=True):
        basis = E(query)
        product = weight
        for coordinate, challenge in enumerate(point):
            product *= ONE + challenge * (ONE + basis * inverses[coordinate])
            basis = basis**2 + roots[coordinate] * basis
        total += product
    return total


@dataclass(frozen=True)
class GluedClaim:
    """One claim folded into the running sumcheck, and the weight it owes back.

    A level's batched queries and an out-of-domain claim differ only in that
    weight: both are a power of the level's lambda times a function of the
    terminal point, restricted to the level's own message coordinates.
    """

    scalar: E  # the power of lambda it was glued with
    fold_start: int  # how many fold challenges preceded the level
    weight_at: Callable[[Sequence[E]], E]


def verify_whir(transcript: Transcript, log_n: int, log_inv_rate: int, target: E, root: Digest, evaluate_basis: Callable[[Sequence[E]], E]) -> None:
    """Verify the base-field multilevel opening with a one-point terminal check."""
    config = derive_config(log_n, log_inv_rate)
    levels = len(config.folds)

    running_quad = transcript.sumcheck_round_poly(3, target)
    folds: list[E] = []
    glued: list[GluedClaim] = []
    current_root = root

    for level, (fold_count, level_rate) in enumerate(zip(config.folds, config.log_inv_rates, strict=True)):
        level_folds: list[E] = []
        for _ in range(fold_count):
            challenge = transcript.sample()
            folds.append(challenge)
            level_folds.append(challenge)
            running_quad = transcript.sumcheck_round_poly(3, poly_eval(running_quad, challenge))

        message_log = log_n - len(folds)
        final_level = level == levels - 1
        # The level's claims, held until its batching challenge is drawn: the
        # OOD claims first, then the query batch (Annex B, Protocol 1 step 1).
        pending: list[tuple[Sequence[E], Callable[[Sequence[E]], E]]] = []
        if final_level:
            residual = tuple(transcript.next_scalars(2**message_log))
        else:
            next_root = Digest.from_halves(*transcript.next_scalars(2))
            ood_point = tuple(transcript.samples(message_log))
            ood_value = transcript.next_scalar()
            pending.append((transcript.sumcheck_round_poly(3, ood_value), lambda x, z=ood_point: eq_eval(z, x)))

        transcript.grind_check(QUERY_GRINDING_BITS)
        block_length = 2 ** (message_log + level_rate)
        queries = sample_queries(transcript, block_length, config.queries[level])
        # One batching challenge per level, drawn once every claim it batches is
        # fixed: the OOD claims above and these query positions.
        lam = transcript.sample()
        query_weights = powers(lam, len(queries))
        # Level 0 committed the K witness, one leaf word per lane; every deeper
        # level a folded E one, three words per lane.
        lanes = 2**fold_count
        words = transcript.merkle(current_root, block_length, queries, lanes if level == 0 else 3 * lanes)
        rows: list[Sequence[K | E]] = [tuple(reversed(row)) for row in words] if level == 0 else [_ext_row(row) for row in words]
        enforced = _enforced_sum(rows, level_folds, query_weights)

        # Every commitment, including the last one, enters through an intro
        # message; the level's claims are then batched with powers of `lam`,
        # the running claim keeping lam^0 = 1.
        batch = (message_log, tuple(queries), tuple(query_weights))
        pending.append((transcript.sumcheck_round_poly(3, enforced), lambda x, b=batch: _induced_weight(*b, x)))
        scalar = ONE
        for intro, weight_at in pending:
            scalar *= lam
            running_quad = [q + scalar * i for q, i in zip(running_quad, intro, strict=True)]
            glued.append(GluedClaim(scalar, len(folds), weight_at))

        if final_level:
            # Finish the remaining sumcheck rounds and close on one evaluation
            # of every basis at the resulting point.
            tail_folds: list[E] = []
            for round_index in range(message_log):
                challenge = transcript.sample()
                running_target = poly_eval(running_quad, challenge)
                tail_folds.append(challenge)
                if round_index + 1 < message_log:
                    running_quad = transcript.sumcheck_round_poly(3, running_target)
            # Each glued claim is rebound at the terminal point: the fold
            # challenges its level fixed after it was made, then the tail.
            point = folds + tail_folds
            lane_folds = config.folds[0]
            weight = evaluate_basis(point[lane_folds:] + point[:lane_folds])
            for claim in glued:
                weight += claim.scalar * claim.weight_at(folds[claim.fold_start :] + tail_folds)
            terminal = weight * multilinear_eval(residual, tail_folds)
            require(terminal == running_target, "WHIR terminal check failed")
            return
        current_root = next_root

    raise VerificationError("WHIR verification ended without a terminal level")


# Flock reduction -------------------------------------------------------------

# Seven fixed coordinates. Over a group of 64 blocks the equality weights are the powers of g, and two groups weigh 1 and y.
Y = E(0, 1)
FIXED_CHALLENGES = tuple(base / (ONE + base) for base in (*(GEN ** (2**power) for power in range(FLOCK_K_SKIP)), Y))

# The AG skip's multiplication code (doc/leanvm Annex C). A block's 64 bits v are the function f_v = sum_i v_i f_i on a genus-95
# curve, f_i being 1 at the i-th rational point and 0 at the other 63. The curve's affine model, over the challenge field:
#     y^4 + (x + 1) y^2 + (x^3 + x) y + x^7 + x^3 = 0,    AS_DENOMINATOR(x) (z_i^2 + z_i) = sum_b AS_NUMERATORS[i][b](x) y^b
# A polynomial in x is the mask of its exponents.
AG_COUNTER_BITS = 16
AG_COUNTER_STEP = E(0x243F6A8885A308D3, 0x13198A2E03707344, 0xA4093822299F31D0)  # the first 192 bits of the fractional part of pi
AG_AS_DENOMINATOR = 0xC33
AG_AS_NUMERATORS = ((0x684, 0x47, 0x24, 0x1B), (0x342, 0xAA, 0x1E, 0x16), (0xE4, 0x63, 0x11, 0x14))
AG_PRODUCT_DENOMINATOR = 0x2A02880A002A2
AG_BASE_DENOMINATOR = 0x842E80B6
# Bit i of slot 32 (4 a + b) + d: the monomial m_a y^b x^d enters f_i, over AG_BASE_DENOMINATOR, m the eight products of the z.
AG_BASE_SLOTS = (0x0, 0x100, 0xA0ACF147ED3D1EFE, 0x59CEB77FBFD95183, 0x4A4DC20958563B2C, 0x8F40E47878B7268E, 0x3B9DC3D823F530D, 0xD54B8D135128990F, 0xB6D475B91A4F21C1, 0x2B46ABC9C64F4A41, 0xC447F8BD8C39DFCC, 0xCDF81744288307CF, 0xD7E718773CFAB81D, 0x1C9BB19F038A733, 0xB9BB586C03DE823F, 0xC7EE5E2B065CFB59, 0x11934D38D972688A, 0xB9CF72ECEDB3876F, 0x19AD8816783971A, 0x19A32DA84727F9A8, 0x4A79D646D976D17D, 0x22D70D54FDA29DEE, 0x2E6E5C3D757C0E3B, 0xCDF591E122C54C26, 0xB5998DA5DFC3A758, 0x6A976E8D1DCA7166, 0xEE32E9CB942FD8C9, 0xCB36624ECCEF9E5A, 0x5CFE1518C807A390, 0xCDB348992A38BED4, 0x86DC4CD80F164E27, 0x1, 0x10100, 0xEC49E1AB02527048, 0x8FF63DE5D9E892DF, 0x64E7EFEA7B253684, 0x6E53D9D9C6E6F8DA, 0x612DB7A93EDDCAEB, 0x901C878521F82E85, 0xA0753F9F52BAF952, 0x1AB09B085C0B6400, 0xCF7EBD0A6733D99, 0x6089B3162AE6CE8E, 0x660FCAB5D92990AE, 0x52625A9B97421830, 0x35F7EA2A4194A8B3, 0x9BDC55C09CBB0CDE, 0xF543426036086C30, 0x87122A593953F9B9, 0x112B7AE7B413ED09, 0xF4C8398937C04C02, 0x6ED0D7B607AC6C7E, 0x63139880C837D407, 0x1199DF6F1713A96F, 0xE89BC5B6B6BC2691, 0xD17D6EDF6A4804D3, 0x293792D277070829, 0xEA66FED0480FFB55, 0x461F46CA570CBFE3, 0xA490AA2B3ACE6A11, 0x5545DF0213F00B07, 0x12524642A1F3A14E, 0x0, 0x0, 0x101000000, 0x4DB834583912C279, 0x70D68FBC670E642A, 0xC5DBFF2CD5BB1C26, 0x645CA9D7B4F2058B, 0xA01A13083F6C8134, 0xA8A0DE4E2204366A, 0xB1011C97702CAFE9, 0x4193D36FC0C8EDCC, 0x9EE64B7992EA4DA1, 0x3B35447D74B24A2E, 0xEB3A85B0AF478AC2, 0x6EA14F0D6D3A28DA, 0xFA1A55BCE227FD43, 0xB79C69FB4E87960B, 0xD2B097BB611DD94D, 0x3C90CA3706DABB8B, 0x4965F08B72C42F85, 0xD00BDEE506CDBE7D, 0x88B37812D3820191, 0x40065EB74A5F1682, 0xC029724028556FEE, 0xC5A9513FC67505BD, 0x8E7A05112C3B5FBC, 0x8B46E5E79ECD0677, 0x4951419D18291D88, 0xFCC2B77D75CF5E46, 0x3DB7670A07F1021, 0x0, 0x0, 0x0, 0x0, 0x101010100, 0xA1F1D5F23B40B331, 0xFF8141BB61F4FD4F, 0x40A711542C367BF, 0x23CD414E762F670B, 0xAB52E47270E2E46D, 0x3436361917393197, 0x25F26AB75659B60D, 0x34A416B898D9F534, 0xA77693A6BC237DEE, 0x5886DF3B183AF505, 0x8F306A4426315D0A, 0xBA6F71E2E1230D8C, 0xD5DC478DFB202D6A, 0x7568EC7334849D0A, 0x3D7A38756D7A0C82, 0xD4C026E44CF0C5B2, 0xBD834547E6B9E615, 0xEE3EDADD6CA8A392, 0x2CD1A3F3B6FC6458, 0xA1913D742A1B3369, 0x907BDAD405E4A34C, 0x2A3B68C33A2995F, 0x2B362F101980E992, 0x503B5007AD9F7292, 0x430DFB71DF88CB91, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x300, 0x7FAF6CAD38A58A74, 0x67844749B97D04A3, 0x5CF6F9A055C60909, 0x5CCAF5A3F609F6CA, 0x1BE4241BD1188EE4, 0x90C909A3F505CA36, 0xD4E8E8D48DDBB218, 0x417DBE4E1BBDD87D, 0x6C3AFAA35A050A39, 0x4B22127BD71D7722, 0x75CCC067A7F529D8, 0xAC39CA60F6FA36FA, 0xA3F6C96FA6C90AF5, 0x424171BE144D2482, 0x9847B889B97D075C, 0xB2824D4D14BD248D, 0xD28BBBE11E87D187, 0x9B7B7746BAB2F75C, 0x863F0C57A8C52517, 0xC65C6FC9905F605C, 0xD28B4B2E1D4BEDB7, 0x94778BB6497E385C, 0xA996A5693659A696, 0xDAC9F904FD3C2F22, 0xC44DB11540743DAA, 0x9959655A96669A59, 0x22477721B28BDE7B, 0x77E2EE888812B8D1, 0x7B18D25BC4BCDA9, 0x3, 0x30300, 0x3B7E82EA1C87CD6A, 0x14D824D872D7B224, 0xE4D7E4E47D2B7217, 0x88E2DD7BD72E7B2D, 0x28E8EB287D278224, 0x53FACAA0F63AF9F6, 0x5CC50A6C56C9F509, 0xFEE2E2238F2861C6, 0xFF0CF03CF00CFCC0, 0xE53A3538A133EFEE, 0x5A596A9A6A9AA966, 0x35A0630AC0906F93, 0x6CF50AAC06FACAF5, 0x3E1DEDD073D8AEC5, 0x57484B76B5BE04A3, 0xA9656659C5A95599, 0xBC50606EC76A4584, 0x8AC00F54F8C62ADB, 0x36939CF6C35F9F63, 0x6AA59AA596969555, 0xE39AAA31C293734E, 0x3F03FCFA3030FCC, 0x3EDE1E1C8C249E09, 0xFAAFAC09C0A3506C, 0xABB88875B57E085C, 0xC00FCF3C03F3C30F, 0xADD7D4BC7612A8FC, 0xAFF6C69005390A39, 0x64874B4AEA7EC4A0, 0x0, 0x0, 0x303000000, 0x96C9CCACF53A3A3, 0xB3ACAF6EC7594A78, 0x647748BA4ABD3753, 0x5844748619823B5C, 0xEA3935040DF320E2, 0xE8D8E7D471DB7ED7, 0xD056560D6E5FB3B1, 0x117B4BED417BD277, 0x32EEEDDC23E89EF9, 0x99390F53C6FA0A0, 0x6847BBBAB68D0B6C, 0x1F555AC1615FB3B2, 0xCE211D23832BAE09, 0xF0C0FFF0AF0CF0F3, 0x94BB8BBA1A4108A0, 0xAD24EB8C26216B3C, 0x966599A6C6A65555, 0x2FA6AA0D6263B372, 0xAFF9CAAF55F53936, 0x2FA996F26D53BC8D, 0x28D72B24812B41E4, 0xC4418EE54047C1A5, 0x9FC5C6A00ACA3AC5, 0xF56063063CA06FAF, 0x50C6FAA009C6C5C5, 0x6B4478864AB1F4AC, 0x8A0C33ABFB39E618, 0x0, 0x0, 0x0, 0x0, 0x303030300, 0x32121E23D3D46DC9, 0x71817E41EBBEE44D, 0xAFF5F5930A053909, 0x1366A901C1AFB072, 0xA3F53590F9C9F536, 0x1C96963162A34C4D, 0x8F90506E986989B4, 0x66595A959A66A665, 0xD5FAC53B5DF02CED, 0x696695A969965556, 0x1AF536080EF32FDE, 0x300CFC0CA3F0FCFF, 0x7A3F3FABA7C52528, 0xB1BD7E7E1B42E77D, 0x79F00C97A7C61627, 0xF4BD8D15BF74F299, 0xDB2BD72872288D27, 0xA03606A0A936C9F9, 0xBA3F03645B35D518, 0x4AC3CF98583AEAEB, 0xD1B48812BD872D47, 0xCE22DED37C28AD3A, 0x4F6C6F9E375A89B8, 0xD284BBDDEE472288, 0x709C539E94554944, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x500, 0x38DB77BFDF12CD90, 0xD069CA3497C3D5D7, 0x203CC03B6299DA28, 0x9E14B84C1F87FDF0, 0x672E82E0D047C23A, 0xE1D77887E84178D7, 0x2CF30F97C8F6EAE7, 0x8E7EDBE811B8247E, 0xDACC9F64F896752D, 0x1B27782D12EE7DD8, 0x222212A43416439, 0xF7878E8F29143439, 0x66CC9CC3CC6C39C6, 0x842B741811B7DE8E, 0xA822D420BC1194C9, 0x9EBB1816EF88F250, 0x73FCA06257A9EA1D, 0x336363C3C36CCC39, 0x5C90C00CAA609ACA, 0x4A60C9A46160D37B, 0x41D4E7989D1F4A3, 0x79A9AA98C203BAED, 0x12BDE7814821B8B2, 0x969633C636996696, 0x7E747BB87B478B7E, 0x159A33519E30D971, 0x19005CA754FA43B1, 0x54424BD37CDE0EFC, 0x1B8222D77D147777, 0x5, 0x50500, 0x1565990EF43F838E, 0x9A59AC956903F653, 0x4E8227D7181E27D2, 0x1B2D728887E1228D, 0x7906003DCDF940B8, 0x13FAA6F854A01614, 0x5B481BD61374AB06, 0x677B82B54048973F, 0xFF0500550005F55F, 0xEDB7BD74227EB817, 0xA442EB2619DEF109, 0xD09CCA9EF8C9DAD2, 0xDDE11E412E2DE4E1, 0xE17D8888E8BB2727, 0x63699699AC399969, 0x2CA95F3DC2061FB7, 0xF3C09A5655603A6F, 0xCFF9AC9003F3FCF9, 0xBE7D822DE71BD28D, 0x53306FFCAA9A9F3F, 0xB590C90E0E9F8924, 0xA63A9A0CC0C0CA90, 0x80CC65919293DF72, 0xE4282222ED118D8D, 0xFE1D4429E6D45BF6, 0x7782BD0B344619C, 0xFFF000AA6F05A55F, 0xDCAC0F9D3DF94FE7, 0xE56F33FE0EC57621, 0x0, 0x0, 0x505000000, 0xCD2428BA2F4D376F, 0xD17E8EB7E4B224D1, 0x5F5FF5AA6A5A5A00, 0xD47E2B12EE4D8E8B, 0xA3C03FA3506FCF90, 0x412BED68684AB09, 0xB12228281D147227, 0x28E1BEB44B78411B, 0xDC06F56838A345E8, 0x8B2BD1BD81ED2481, 0xEA6F93F4046086DB, 0x28BB4144DE8711BE, 0x5F0A05A65555A55, 0x550AAA55F5A0A550, 0x6B4BE2BCE528075F, 0x60F3566A095909F6, 0xDD7217023B43B63, 0x6B1B17131A8DAD5F, 0xB2B7ED812871B2E7, 0xFB124B8C13D4AB56, 0xDFCCCA91FD697072, 0xEED44D61C84F4F6, 0x712B2E1D1EE7712B, 0x456F96A191C579DB, 0x91BEE74C8087F8A0, 0x611447ECE58852F5, 0x5D7721D0DC1E3E9C, 0x0, 0x0, 0x0, 0x0, 0x505050500, 0xD841B1B1DB72B1E1, 0x387E7DEFB0426230, 0xE2B8B88BB27BB742, 0xBB772D8D881E7277, 0x93F6F53AA6A309A, 0xC2848D4A4AED9DCF, 0xB818B28BD7D14D48, 0xFA00F5F0F5AF0F55, 0x85963064979C2F88, 0x4242B7D1D87E4DED, 0x36CC63CCC339966C, 0xA55AAA0F05AFA550, 0xA1121BDC1924A403, 0x327128152A123D3A, 0x87884D543E4C4C9, 0x6996CCC353999C39, 0x7711E41B2E8D41E4, 0x550050AAFF000050, 0xB4D27D27181E8D87, 0x3CC93666C6339963, 0x4CF059A2AEF5BC1E, 0x82724854944CEC6, 0x7DB4B4112EDDE41B, 0x865CF0CD37A64042, 0x83AC0A9DCDFCEFED, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xF00, 0x2E747BE2EEB82E7B, 0x599A6A5635956A9A, 0xBDBD4271B771E742, 0x5B474B89E97E0453, 0x7533C06BF7C9DAD8, 0x1E77782D12442D77, 0xF22DD1DF2C149EC6, 0xEC55A90D31AFB3BE, 0x2C59AA3D3D5CBF42, 0xFC3FCF0C5F3030C0, 0x760C0F67A8F91518, 0xD4DB2B1771E77EDB, 0x124847DEB2741DB8, 0xFFF0000F0000000F, 0xF0F0FF0F00FFFFF0, 0xACC5355CA53AC53A, 0x7E717EBD1BBDD481, 0x5E17EB8389DE5BFC, 0x742E2148741D842E, 0x5CCA3553AA353A35, 0xECA55602C15FBCB1, 0x4242BD81B78E174D, 0x2C59A53D3D5CBF4D, 0xFC3FC0F3AF3F30C0, 0xD3A6A53D3D534FBD, 0x987477B5BA42C860, 0x5118147C86D15BF3, 0xAFFAF5A0F5F5FA05, 0xE42728278D1B8228, 0xF, 0xF0F00, 0xD814EB142127BE14, 0xC88E7DEABF473D95, 0xD174741DE148D17B, 0x21747BE2E1B82E7B, 0x8E8171B21BB2D481, 0x57878B7549B13B63, 0x49F00358A4F5E6E4, 0xA7788B8AB6B13B63, 0x32DE2DE02FE79D35, 0xC5A3ACCA93A3ACAC, 0xF000FF000FFF00F0, 0x388E8DEA4F483D65, 0x7E7E814D1B422B81, 0xF88D7EDAB3B43E99, 0xDF696ACE626C7082, 0x3C3C333CA3C33333, 0x217B7BEDE147D174, 0xD2BBBBEEB1781EBB, 0xC9939336C3636393, 0xFEEDE123832BA1F9, 0xEE7878DD1DBB2D88, 0x3F0CFC3FFC03FC0C, 0x22D2ED023EB9139, 0xF5AFA0F590AFAF50, 0x399C633933936C9C, 0x6009F960F6F606F6, 0x9D24D8BFD5E298C0, 0xA66A9A56C5656A65, 0xDD2DED0DC1B61C6, 0x0, 0x0, 0xF0F000000, 0xD71BE4EBDE2841EB, 0xF99090F6CF9F9F9F, 0xB0906CAE9B9A7674, 0x76F30F67A8F91AE8, 0xFA5050F59FAF50A0, 0xADD8D48FD9E16433, 0xDDD2E20D3EB6139, 0xCB414DE6108802A5, 0xCF0303CFF3F30CF3, 0x54B84B89E971FB53, 0xCF0C0C30F303FC03, 0x25363AC4FDCC2FD2, 0xB35FACAD34A5464B, 0xAF05F55FFA0AF5FA, 0xF882812ABC4B3169, 0xCC3CC3C3ACC3CC33, 0xB0606C516B9A7984, 0xBBD41D6E37B0E59, 0x6EE4E74C8A2258FF, 0xAE181B8C76D1ABFC, 0x61E417B37ADD57F0, 0xCC33CCC35CC33333, 0x5AA5AA55655AA5A5, 0xB09F93AE946A767B, 0x48121284D82147E2, 0x2D4B4411BE78EE44, 0x790CF097A7F61518, 0x0, 0x0, 0x0, 0x0, 0xF0F0F0F00, 0xF0F0FF0FF0FF0FF, 0x106A69FE91907381, 0x4A3033ABFB3A262B, 0xA96A95A6356A9595, 0xEBD8D7D782E48D27, 0x1CA5A9FDCEA0BCBE, 0x806C906E68667577, 0xAA0AF0A605FA05F, 0x5DD8DB7FD9119B3C, 0xAD28DB7FD6E16433, 0x20966531926C708D, 0x9009096009F6F9F9, 0x5FF5FA5FF505FAFA, 0x87D7EDABCB4CE66, 0x9A56569A6656A656, 0x7C5CA092385945B8, 0xA7788B7AB64EC49C, 0x944B47B9158D0750, 0x2D4B4411BE87EEB4, 0x69999969C6699666, 0x7811114B2B22441E, 0x4E728D82E7B1D87D, 0xC8817D1A4048CD65, 0xCE1E12E370275DFA, 0x377172154FB8CD9A, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1100, 0x3E2D6A8A9DBE34E4, 0x1E296C2F4533809, 0xF2E1B79B709CF8F5, 0x47843F12117B12B7, 0x8CF9BEC8AD475412, 0xF37430A6D7ED3F74, 0x3AC53A53DD53066F, 0xD7274127330AD827, 0xD5A1D9BF841346C, 0x3936EB14724EFA36, 0x6C3663D8440AEB05, 0x4688FCC1A4B191C9, 0xB090D7C7B0480E59, 0x58A57B318F8DAD28, 0x1B7964AF453E509, 0xCF2EF39A033FCF7B, 0x1A7EA00BB0C0C2E2, 0x494B1D31DCD8E96C, 0x6C9C8D41A9C6D805, 0x864744AB323A379F, 0x73249C40379A329A, 0x295C5F6D9484A40C, 0xC122184B2FC6ADE, 0xE1D2E1C34E78B42D, 0x43D71816BCB4A84B, 0x4DF65CDB638E06F6, 0x7BCFED59F30359A9, 0xC074FCC00C121D74, 0x9B770385B6B11914, 0x11, 0x111100, 0x583C3FFDABD84328, 0xA822FCE3802819EB, 0x5BDEEEEFDF6FFB71, 0x519F1437FE65EFA9, 0xF45C4E4F86E2A448, 0xB4C3E1A52B1EE178, 0x9A9584EDD87BED59, 0xC0FCED6A7B74B712, 0x6F4DA3359C422481, 0xD174FCE2A0FC84FC, 0xEADBD840ADB85447, 0xFA287DE46FAF5FE4, 0xF714173B5EDDE300, 0xB703741DC5ED9530, 0xE8ACACA33F4DC5AC, 0x68DEFF238C2BEA17, 0xDBBD718109F66FF9, 0x5D7D782F550A082, 0xB4D287698787C3B4, 0xD490E735229F42F6, 0x9AD11DA9EEC04759, 0xC6416336E8F514EB, 0x76481EC219DB29F6, 0x360AD7D78214C66C, 0x5C6F5C17AAAC24C5, 0x22FF443388EEFFCC, 0x61D7184398966478, 0x7AE13F469D63DA28, 0x495A7B8A3114257D, 0x0, 0x0, 0x1141000000, 0xB150C9BE177D4172, 0x6B69594654FADAC6, 0x19C960B34C4494FF, 0xD65C5F7C7995B5C0, 0xF4F6A0E5C71DE0F3, 0xD3C7B13EA729EB1, 0x52934D165178CE3C, 0x55220088C9EE0066, 0x74596A1250D103B7, 0x4BC3D23C0F87C3C3, 0x56C6CC6B414C6E4, 0xEBC67D937D05397D, 0x62CA7204370323B8, 0xD839B11B59057D0A, 0xD12121F328747B74, 0x3F74B8D10C47A6CF, 0x19419FE65E228588, 0x863F97F1F449433, 0x904D7E068E53355C, 0xB7A9CF2E4DFCB7B8, 0xF9CA2418B77EA3CA, 0xEB28D7F50AFAB1B1, 0x360A1B287D365FF5, 0x69786987A35AD25A, 0x3C0A603EE59EDE2, 0x8EE853F6932B90CA, 0x983F690EC28EC7D4, 0x0, 0x0, 0x0, 0x0, 0x1141111100, 0xE96CF652BCA5135A, 0x20CCCF49F71B5D14, 0xECAAA9C1C16CB350, 0x6444740D1A1BE650, 0x8BC08412743FCFA6, 0x14E4C6E4D16328C6, 0xB19C3627BBB1FA8D, 0xEEFF2299124466AA, 0x3B41DB190DDD2F88, 0x77BBCC00362211AA, 0xB9DD9A855B39F7BE, 0xD24B2DB4C65A1E3C, 0x30D10CEDD87BFCC0, 0x54950F0E3DCAB0F6, 0x70A09708A962087, 0x884488EE12446655, 0xD8B19339A6C9F539, 0xB9FFED0D5B5FE605, 0xEA3572734030FE21, 0x6D5CF5834F2EA4E2, 0x123F958B8B0C307B, 0xD2B4B4F00F87873C, 0x1C03C68B5F93890, 0xA8AAED2F6DF56EC9, 0xC2B88823A88104AC, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x3300, 0x3FFC303FA003F330, 0x6B4B7B75B941F8A0, 0x688B88764581379F, 0x7DBE8DBE448214BE, 0x435F9052CB9675B4, 0x241724E72D2B7EE8, 0x8F6C6F9ECB967578, 0x20669A3EC1A0808D, 0xB27E4DBDEB7117B2, 0xB6F0C0640736161B, 0x171717E781D47EE8, 0x4271427E484D2B71, 0x9FF9356FA53AC535, 0x7FAF9F5D68997ABB, 0xF96053F66C5C5C60, 0xFD11DED0D31B9105, 0x450C3C5B58CA1AD4, 0x92181BB0792E970C, 0xB900306BA4F52A14, 0x19363508A1002FDD, 0xDF559AF26D6C4C41, 0xC8718D15407401A9, 0x84ED128428ED8412, 0xC55C5C0663ACACA3, 0x67B74B79198E0B6F, 0xDD8888EEED88DD88, 0x359FACF6C0906F9F, 0x3F30FCC0F3CF3FCF, 0xAD28188F26E1A80F, 0x33, 0x333300, 0xF0C3C33C5CF0C3C3, 0x3E1ED11370279EC6, 0x60F9F99009C5F6CA, 0xBBEEDD4424DDBBDD, 0x9A390063060605C, 0x97478876BAB2C89F, 0x7F9CAC5DC4AA4977, 0xE718D42471178ED4, 0x984887B5B58EF45C, 0x471D2E8B74E2B82E, 0xA9A6A66535A65695, 0xA1D4D74F86D1A4C0, 0x2E748B2E4DB81D8B, 0x98B787B51942F4A3, 0x76C0C3A40BF9D6D4, 0x77EE22BBDBDD88DD, 0x718E714DB77EE7BD, 0x5CF6F69FAACA35F6, 0x1A3AC6C70E3F1FD1, 0xCE22122F801BA236, 0x2C9A99CD9E5C7342, 0x4393A3AD985A8A87, 0xDD8888EE12BBEE77, 0xB42DE1B42B2D78D2, 0x9F06065C09F63A06, 0x3F30FCF30C033FCF, 0x3111EDE32CE45D36, 0xA65665953A656A9A, 0xBBDD11BB772277DD, 0x0, 0x0, 0x3353000000, 0xAD1B188F26E164C3, 0x7C6F6C6D949579B7, 0x7D41418DE8B12772, 0x6F0909ACAAF9F93A, 0xA8444785E5B1089C, 0x92E7D74F2AE2970C, 0x30C3F03FC3F303F, 0x46CCFC945BC619EB, 0x9DE814BF89EDABCF, 0x28D814278DD78DD8, 0x3D21DD1073D49DF9, 0xB72112B728128412, 0xD4E7D424DD24BDE7, 0xB5FC33ABA8F626E8, 0x16F5F63451F013E1, 0xB363606E3B66B644, 0xF47EB1E51CB7F159, 0x4EBEBE8DE8B12772, 0x5CF6F6ACF935353A, 0xA7B4B775468DCB6C, 0x355360F6C0905CAC, 0x33AC3300FF, 0x1355653E92A04CBE, 0x62E8278C251254CF, 0x5887847515BE075F, 0xE6FA353B0D002F22, 0xFCF30CCF033F300C, 0x0, 0x0, 0x0, 0x0, 0x3353333300, 0x5DD8DB807A119400, 0x4F6F6C926B594A7B, 0x25C6C534FD3CDF1E, 0xCD2ED22CD0E85E3A, 0x27281B1BD1EB7DD7, 0x1C5A6A0231634382, 0x61282BBC8AD264F0, 0xA3093A60AA350609, 0x300CF3CF50F3CFC0, 0xCF0CC0FCAFF3FCC0, 0x4C63AC91C4558544, 0x706C9061CB5A754B, 0xFA6C5FC63C9C5F5F, 0x48DEDE487B127BED, 0xDE11D202327ADF5, 0xC1E11DEC8FD86139, 0x47E22EB88B1D8BD1, 0xC5A390CA6353536F, 0xFC3FF3CFFC3F03C0, 0x4E41417217B1D8BE, 0x94787B4615BECB5F, 0x64BB477AB67D089C, 0xE4EB14EB72287227, 0x1B142727DE288DD8, 0x81817E42B8BD247E, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x5500, 0x6BB41DB98F72F8F5, 0x366CC66CA6C96C6C, 0x2AC9CA6EF266D022, 0x1188222212BB2277, 0xCC3366CCAC669933, 0x848B2148E1477B74, 0xC0FCFCC06903F303, 0x46FF0358C1A01914, 0x9BEE47E37F8208AF, 0x817E2BE871E82481, 0xEED1176162BFB06, 0x5E4D1B7C797BF159, 0x5FFAAF5060A05050, 0x10C069A46E607C2B, 0x9669C3965C3CC369, 0x17BDE82BD22BB242, 0x79A90067CDF6BF17, 0xC396963CC6693C69, 0x90095C35F9F9AC09, 0x148B4D37CDB0BA3, 0x5BED4423167E51F9, 0xFFFFFFFF0055AAAA, 0x9BEEED1C807D08FA, 0x1A3AC6A1F13F2C2E, 0xD84E4E4EB4721BE4, 0x72E41B4E2E8D4EE4, 0x1482D7821841287D, 0x682177BA45189D35, 0xF44D1B29E37B5BF3, 0x55, 0x555500, 0xDD11EEBBDB774411, 0x11D4BD383DB0BA3, 0x2AC935C4F2992F77, 0xD21E4B4B2B2D4BB4, 0x3C693CC3A3C3C369, 0xB65AF3FDAB0516E4, 0x944BE2138FD8AD5F, 0x94B41DB970D8AD0A, 0x7599CF9408937F8D, 0xD3A90032A809BF17, 0xD59C9F910D997ADD, 0x5D8D712A29EE9499, 0x50F5F5F56F05A0F5, 0x65F3599A03A6FCF3, 0xE650535D3B0049BB, 0xA9953F56CA9530C0, 0x7903FF9832A3BF42, 0xFE48B47983DB5E5C, 0x2E8B74481EB87B8B, 0xB184E831CD10EF3, 0xD303FFCD57A3EABD, 0x9363C963CCC69C63, 0x5F5F50A0A055FF5, 0x4F6FC60BF13F7984, 0x760CF03D58F94F18, 0x5D72DBD5D611C166, 0xA0FA055060A0FAAF, 0xC7D4824F4F483D6A, 0x1E87D2781D1E2D78, 0x0, 0x0, 0x5565000000, 0xAC9F605C5A3AC5CA, 0xF5AA50F955A5A0F, 0x6AA9A93FF3FC0CFC, 0xF2D22E7546146193, 0x212ED1ED8B488B84, 0x7FC99F6E686685DD, 0x98D187B5D0BDC790, 0x71DB8E18E418D471, 0xEF3FC30E0B9FD67E, 0x728818FD9B49BC3, 0x5228D48FBC4B9B69, 0xD1218BB7E1ED848B, 0x8A66303E6D6C7F72, 0x6AFC566AF30359FC, 0xE3A5A6A831AF434E, 0xD1DEDEB7E1EDD174, 0xE12D7878E21ED287, 0xCD7B78E02F176D3A, 0xB12727728D4ED872, 0xCC6699CCAC99CC33, 0xFFFFAAAA65AA00FF, 0xFF0F0A56AA50F0F, 0xF0F0A5A56A0FF0F0, 0xEA603651013089DE, 0x84DEDE481E12D18B, 0x2F693F64F89CDA28, 0x2593906167C3DF78, 0x0, 0x0, 0x0, 0x0, 0x5565555500, 0x718E8EB2814DD4DB, 0xFF0F0A5F05A5A0F, 0x3C3C3CC3A3C3C369, 0xB60FF30254FABCE4, 0x274EE4E4D172E4B1, 0x987B2DB5B5E8C7C5, 0x148B42C83240B09, 0xC0A9036A0C03A656, 0x7B2121B71E122E74, 0x69963CC3A36969C3, 0x6D81281A2A1D3D3F, 0xAEE8EB73EC8B5456, 0x2F3C959B07C98F82, 0x7306FAC852FCEFB8, 0xABE21E79E624A109, 0xEE888822EDBB77DD, 0x29F65F6DC759B548, 0x14D77DD782148282, 0x2B2B81BD14E824D4, 0x827DB2AB344C1CC, 0x7F36359168332F88, 0xFC3F3F56CA3FCF6A, 0xC93939933C36936C, 0xCBE44D168A2D02A5, 0xDDBBBBEEDB7711BB, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xFF00, 0x43A05CADCBA546B4, 0x2E8B8BE2E1B82E74, 0x817E81BD14BDDB81, 0x5777747AB6B1C49C, 0x74D1D1B8741D8B2E, 0x87E1E1B4D4D2B4E1, 0xB1728D8DE84E2772, 0xB3AFAC5DC4554944, 0x3BBEBD191F770DAA, 0x23A65A3D3DACB0B2, 0x3B41BD191F77F2AA, 0x60F9066FF6090906, 0xAC35CAA3A53AC535, 0x842121B77BED7BDE, 0x2B2B2B178E1771D4, 0x54484B86E6710B5C, 0x7533CF94F7C62A27, 0x7F63609168668588, 0x62DBD840DA1267CF, 0xDE7B84ED1148DE84, 0x5CC53AAC55CACA3A, 0x1A3A39F40E3F2CD1, 0xC33C3C3CA3C33C3C, 0xF00F0F0F0F0F0F0F, 0xFF000000000000FF, 0xFF0000FF00FF0000, 0x1535C90401CFDC21, 0x6AA9566A69565956, 0xE2B8B8D1B2741DB8, 0xFF, 0xFFFF00, 0x533535A35A3A3ACA, 0x49F00CA8ABFAE9E4, 0x52D72B70D9E164C3, 0x872712A4C44C166, 0xE1211238CD45106, 0xBBDDDD7788117722, 0x760CF097A7F9E518, 0x94B4B7B9158D07A0, 0x2DB4B4E14E781EB4, 0x48EDED842821B7ED, 0xE90A090751F0EC1E, 0x3DDE22EFDF1862CA, 0x3FFCFC3F0CFCF303, 0x9556A9956956A6A9, 0xA447BB89167EFB53, 0xB8E2E274D8D147E2, 0xCEEE121C7F285DFA, 0xE35A5902CE5043B1, 0x206665C19293808D, 0x181818DB22DBBDE7, 0xE247B8D14D741D47, 0x718E8EB2E44D2B71, 0x8ACCCF6B08C62A27, 0xB4D4ED61C84F159, 0x4C50535DC45549BB, 0xC44142E61F880DAA, 0x366C6C39C39C9393, 0x7353AF9D37A9BAB8, 0xDA39C534023C20D2, 0x0, 0x0, 0xFFFF000000, 0x8BD12E478B1D8BD1, 0xF330300CA0303F30, 0x260605375203EFED, 0x14D728287D148228, 0xA0FAFA5005F5FA05, 0xB7EDED7B28214812, 0xAF0AF55FF505F5F5, 0xD6F60AC7A20C1F1D, 0x23595AC23D534FB2, 0x922B28B02A1D683F, 0xAA5555559A5555AA, 0xAAAA55AA6555AA55, 0x6224274025ED6730, 0xBF609CAE64657674, 0x18E718DB2224BD18, 0xF22DD1DF23146139, 0x77EEEEBB24DDBB11, 0x3F0303C0F3FC0C03, 0x5DD8247FD6EE94CC, 0x4BD22D7887E1782D, 0x99996699C9996699, 0x2E8B74E2E1B82E74, 0x817E7EBDEB42DB81, 0x36936CC63C636C6C, 0xAB48B479E68E0BA3, 0x6006F99009F60906, 0x378E72EABF47329A, 0x0, 0x0, 0x0, 0x0, 0xFFFFFFFF00, 0xD8E41B1BD1274E1B, 0x3C0C003503F303F, 0xA8887485494E3B9C, 0x53CACAA3A53A3A35, 0x387E7D1AB0483D6A, 0xFA5FA0F590AF5FA0, 0x5BB8448916810453, 0x1428282882147D28, 0x92D4284F2A1D683F, 0x500AF55F0AFA0AF5, 0xBB2B1D6E37B0E59, 0x6EEB174C85DDA7FF, 0x2539C5CB02C3DF2D, 0x569595A9356A9A95, 0x355353C56C5CA3AC, 0x406063516465768B, 0x1D4747D1B274E247, 0xBC5FA352CB5AB94B, 0x78E1E1B42BD2B4E1, 0x3F0303C0F3FC0CFC, 0x5DD8247F29116BCC, 0x69969669C6696969, 0x3BBE4219E0880DAA, 0x42424281B77EE742, 0xA778848A46BECB93, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)  # fmt: skip
# The 158 products f_i f_k that, with the 64 squares, are a basis of the product code. The skip message is sent over them.
AG_PAIRS = ((0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12), (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (0, 20), (0, 21), (0, 22), (0, 23), (0, 24), (0, 25), (0, 26), (0, 27), (0, 28), (0, 29), (0, 30), (0, 31), (0, 32), (0, 33), (0, 34), (0, 35), (0, 36), (0, 37), (0, 38), (0, 39), (0, 40), (0, 41), (0, 42), (0, 43), (0, 44), (0, 45), (0, 46), (0, 47), (0, 48), (0, 49), (0, 50), (0, 51), (0, 52), (0, 53), (0, 54), (0, 55), (0, 56), (0, 57), (0, 58), (0, 59), (0, 60), (0, 61), (0, 62), (0, 63), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19), (1, 20), (1, 21), (1, 22), (1, 23), (1, 24), (1, 25), (1, 26), (1, 27), (1, 28), (1, 29), (1, 30), (1, 31), (1, 32), (1, 33), (1, 34), (1, 35), (1, 36), (1, 37), (1, 38), (1, 40), (1, 41), (1, 42), (1, 43), (1, 44), (1, 45), (1, 46), (1, 47), (1, 48), (1, 49), (1, 50), (1, 51), (1, 52), (1, 53), (1, 54), (1, 56), (1, 57), (1, 58), (1, 60), (1, 61), (1, 62), (1, 63), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15), (2, 16), (2, 17), (2, 18), (2, 19), (2, 20), (2, 21), (2, 22), (2, 23), (2, 24), (2, 25), (2, 26), (2, 27), (2, 29), (2, 32), (2, 58), (2, 62), (2, 63), (3, 17), (3, 18), (3, 57), (4, 26), (5, 41), (7, 22))  # fmt: skip


def bit_polynomial(mask: int, x_powers: Sequence[E]) -> E:
    return E.sum(x_powers[degree] for degree in range(mask.bit_length()) if mask >> degree & 1)


def ag_skip_weights(x: E, y: E, z: Sequence[E]) -> tuple[E, ...]:
    """The 64 weights `f_i(Q)` of the curve point `Q = (x, y, z)`, which must be in the code's evaluation set."""
    x_powers, y_powers = powers(x, 50), powers(y, 4)
    as_denominator = bit_polynomial(AG_AS_DENOMINATOR, x_powers)
    base_denominator = bit_polynomial(AG_BASE_DENOMINATOR, x_powers)
    poles = as_denominator * bit_polynomial(AG_PRODUCT_DENOMINATOR, x_powers) * base_denominator
    require(bool(poles), "AG skip point over a pole")
    quartic = y**4 + (x + ONE) * y**2 + (x**3 + x) * y + x**7 + x**3
    require(not quartic, "AG skip point off the base curve")
    for z_i, numerators in zip(z, AG_AS_NUMERATORS):
        rhs = E.sum(bit_polynomial(numerator, x_powers) * y_power for numerator, y_power in zip(numerators, y_powers))
        require(as_denominator * (z_i * z_i + z_i) == rhs, "AG skip point off the cover")

    z_1, z_2, z_3 = z
    cover = (ONE, z_3, z_2, z_2 * z_3, z_1, z_1 * z_3, z_1 * z_2, z_1 * z_2 * z_3)
    weights = [ZERO] * K_BITS
    for slot, mask in enumerate(AG_BASE_SLOTS):
        monomial = cover[slot // 128] * y_powers[slot // 32 % 4] * x_powers[slot % 32]
        for i in range(mask.bit_length()):
            if mask >> i & 1:
                weights[i] += monomial
    scale = base_denominator.inv()
    return tuple(weight * scale for weight in weights)


@dataclass(frozen=True)
class ZerocheckResult:
    skip_weights: tuple[E, ...]
    chi: MultilinearPoint
    v_a: E
    v_b: E
    v_c: E


def verify_flock_zerocheck(log_n: int, transcript: Transcript) -> ZerocheckResult:
    """The zerocheck: one AG skip round, then nflock quadratic ones.
    C rides those rounds with AB, so all three claims come out at one point."""
    # The point r: seven fixed coordinates, the rest sampled.
    r = (*FIXED_CHALLENGES, *transcript.samples(log_n - FLOCK_K_SKIP - len(FIXED_CHALLENGES)))

    # The skip message P over the pairs; its 64 coordinates over the squares are zero by the zerocheck identity.
    # Then the skip point Q: the sampled x moved by the prover's counter, and the prover's y, z over it.
    p_pairs = transcript.next_scalars(len(AG_PAIRS))
    x_0 = transcript.sample()
    delta, y, *z = transcript.next_scalars(5)
    require(int(delta) >> AG_COUNTER_BITS == 0, "AG skip counter out of range")
    skip_weights = ag_skip_weights(x_0 + AG_COUNTER_STEP * delta, y, z)
    v_p = E.sum(p * skip_weights[i] * skip_weights[k] for p, (i, k) in zip(p_pairs, AG_PAIRS))

    # nflock quadratic rounds on P, closed by v_a, v_b.
    chi, running = sumcheck(transcript, v_p, 3, r)
    v_a, v_b = transcript.next_scalars(2)
    v_c = running + v_a * v_b
    return ZerocheckResult(skip_weights, chi, v_a, v_b, v_c)


def verify_flock_lincheck(zc: ZerocheckResult, transcript: Transcript) -> tuple[MultilinearPoint, tuple[E, ...]]:
    """Lincheck at the quirky point (Q, chi): the claim's point, then its 64 slices s."""
    alpha = transcript.sample()  # batches the two matrix identities, the c claim and the constant-position claim
    # e_row: the skip point's weights in the skip coordinate, eq in the slot variables.
    skip_weights = zc.skip_weights
    chi_in = zc.chi[:FLOCK_NUM_LINCHECK_ROUNDS]
    e_row = [weight * value for weight in eq_kernel(chi_in) for value in skip_weights]

    # The 8 rounds that bind the high column coordinates, leaving 64 unfolded.
    claim = zc.v_a + alpha * zc.v_b + alpha**2 * zc.v_c + alpha**3
    round_challenges, r_lc = sumcheck(transcript, claim, 3, [None] * FLOCK_NUM_LINCHECK_ROUNDS)

    # The residual, then the terminal identity: pin term and c term included.
    # C = I, so the c weight is e_row itself, and both sides being tensors it
    # collapses to eq(chi_in, chi_in_prime) times a 64-term combination.
    s = tuple(transcript.next_scalars(K_BITS))
    chi_in_prime = tuple(reversed(round_challenges))
    w_col = [value * weight for weight in eq_kernel(chi_in_prime) for value in s]
    terminal = (
        blake2s_bilinear(alpha, e_row, w_col)
        + alpha**2 * eq_eval(chi_in, chi_in_prime) * dot(skip_weights, s)
        + alpha**3 * w_col[BLAKE2S_CONSTANT_COLUMN]
    )
    require(terminal == r_lc, "Flock lincheck terminal mismatch")
    return chi_in_prime + zc.chi[FLOCK_NUM_LINCHECK_ROUNDS:], s


def blake2s_row_values(column_weights: Sequence[E]) -> tuple[list[E], list[E]]:
    """Compute `A0 w` and `B0 w` by one forward walk of the circuit."""
    size = 2**BLAKE2S_R1CS_LOG_SIZE
    constant = BLAKE2S_CONSTANT_COLUMN
    message_base = 640
    counter_low = 1152
    counter_high = 1184
    final_flag = 1216
    last_node_flag = 1248
    gates_base = 1280
    gate_stride = 184
    left_values = [ZERO] * size
    right_values = [ZERO] * size

    def slots(base: int) -> tuple[E, ...]:
        return tuple(column_weights[base + bit] for bit in range(32))

    def literal(value: int) -> tuple[E, ...]:
        return tuple(column_weights[constant] if value >> bit & 1 else ZERO for bit in range(32))

    def xor(x: Sequence[E], y: Sequence[E]) -> tuple[E, ...]:
        return tuple(a + b for a, b in zip(x, y, strict=True))

    def rotate_right(word: Sequence[E], amount: int) -> tuple[E, ...]:
        return tuple(word[(bit + amount) & 31] for bit in range(32))

    def add(x: Sequence[E], y: Sequence[E], carry_base: int) -> tuple[E, ...]:
        carry = ZERO
        output = []
        for bit in range(32):
            if bit < 31:
                left_values[carry_base + bit] = x[bit] + carry
                right_values[carry_base + bit] = y[bit] + carry
            output.append(x[bit] + y[bit] + carry)
            if bit < 31:
                carry += column_weights[carry_base + bit]
        return tuple(output)

    def add3(x: Sequence[E], y: Sequence[E], z: Sequence[E], base: int) -> tuple[E, ...]:
        """Fused three-operand add: 31 majority rows then 30 ripple rows.

        The majority of bit `i` is `maj_aux[i] + z[i]`, since over GF(2)
        `(x+z)(y+z) = xy + xz + yz + z`; then `x + y + z` is the ripple sum of
        `p = x^y^z` against `q[i] = maj[i-1]`, whose bit 0 is zero, so the
        ripple layer's bit 0 needs no row and slot `base + 31 + i - 1` carries
        bit `i`.
        """
        majority = []
        for bit in range(31):
            left_values[base + bit] = x[bit] + z[bit]
            right_values[base + bit] = y[bit] + z[bit]
            majority.append(column_weights[base + bit] + z[bit])
        ripple_base = base + 31
        carry = ZERO
        output = []
        for bit in range(32):
            q = ZERO if bit == 0 else majority[bit - 1]
            left = x[bit] + y[bit] + z[bit] + carry
            output.append(left + q)
            if 1 <= bit <= 30:
                left_values[ripple_base + bit - 1] = left
                right_values[ripple_base + bit - 1] = q + carry
                carry += column_weights[ripple_base + bit - 1]
        return tuple(output)

    def linear_rows(values: Sequence[E], base: int) -> None:
        for bit in range(32):
            left_values[base + bit] = values[bit]
            right_values[base + bit] = column_weights[constant]

    for base, length in ((0, 256), (message_base, 512), (counter_low, 128)):
        for row in range(base, base + length):
            left_values[row] = column_weights[row]
            right_values[row] = column_weights[constant]

    # v[0..8] = h, v[8..12] = IV[0..4], v[12..16] = IV[4..8] ^ (t_lo, t_hi, f0, f1).
    state = [slots(32 * word) for word in range(8)]
    state.extend(literal(BLAKE2S_IV[word]) for word in range(4))
    state.extend(xor(literal(BLAKE2S_IV[4 + word]), slots(base)) for word, base in enumerate((counter_low, counter_high, final_flag, last_node_flag)))

    for round_index in range(10):
        sigma = BLAKE2S_SIGMA[round_index]
        for gate_index, (lane_a, lane_b, lane_c, lane_d) in enumerate(BLAKE2S_G_LANES):
            gate = round_index * 8 + gate_index
            gate_base = gates_base + gate_stride * gate
            a, b, c, d = state[lane_a], state[lane_b], state[lane_c], state[lane_d]
            mx = slots(message_base + 32 * sigma[2 * gate_index])
            my = slots(message_base + 32 * sigma[2 * gate_index + 1])
            a1 = add3(a, b, mx, gate_base)
            d1 = rotate_right(xor(d, a1), 16)
            c1 = add(c, d1, gate_base + 61)
            b1 = rotate_right(xor(b, c1), 12)
            a2 = add3(a1, b1, my, gate_base + 92)
            d2 = rotate_right(xor(d1, a2), 8)
            c2 = add(c1, d2, gate_base + 153)
            b2 = rotate_right(xor(b1, c2), 7)
            # Every lane cascades: this encoding materializes no intermediate word.
            state[lane_a] = a2
            state[lane_b] = b2
            state[lane_c] = c2
            state[lane_d] = d2

    # out[w] = h[w] ^ v[w] ^ v[w+8], the only materialized words.
    for word in range(8):
        out = xor(xor(state[word], state[word + 8]), slots(32 * word))
        linear_rows(out, 256 + 32 * word)

    left_values[constant] = column_weights[constant]
    right_values[constant] = column_weights[constant]
    return left_values, right_values


def blake2s_bilinear(alpha: E, row_weights: Sequence[E], column_weights: Sequence[E]) -> E:
    """Compute `e_row^T (A0 + alpha B0) w_col` from the two forward row vectors."""
    left_values, right_values = blake2s_row_values(column_weights)
    return dot(row_weights, left_values) + alpha * dot(row_weights, right_values)


def verify_flock(log_n: int, transcript: Transcript) -> tuple[MultilinearPoint, tuple[E, ...]]:
    """The reduction in protocol order: zerocheck, then lincheck. What it leaves is the
    point and the 64 claims s[i] = z(i, point), i < 64, for ring switching to bind."""
    zc = verify_flock_zerocheck(log_n, transcript)
    return verify_flock_lincheck(zc, transcript)


# Ring switching --------------------------------------------------------------

# The Frobenius shifts of the six stages composing Phi, one challenge each.
RING_MAP_SHIFTS = (32, 16, 8, 4, 2, 1)


def _phi(value: E, challenges: Sequence[E]) -> E:
    """The drawn map, stage by stage: `a_p+1 = a_p + f_p a_p^(2^shift)`."""
    for challenge, shift in zip(challenges, RING_MAP_SHIFTS, strict=True):
        value += challenge * value ** (2**shift)
    return value


def _ring_weight(r: MultilinearPoint, r_prime: Sequence[E], coefficients: Sequence[E]) -> E:
    """The weight `W(u) = Phi(eq(r, u))`, extended and evaluated by the opening at
    `r_prime`: `sum_k c_k prod_n (1 + r_n^(2^k) + r'_n)`."""
    total = ZERO
    frobenius = list(r)
    for c in coefficients:
        product = c
        for value, challenge in zip(frobenius, r_prime, strict=True):
            product *= ONE + value + challenge
        total += product
        frobenius = [value**2 for value in frobenius]
    return total


def ring_switch(point: MultilinearPoint, s: Sequence[E], transcript: Transcript) -> tuple[E, Callable[[Sequence[E]], E]]:
    """The 64 claims s[i] = z(i, point) become the one dense claim `sum_u W(u) qflock(u) = target`.

    Draw Phi once they are fixed, then take the target `T = sum_i x^i Phi(s_i)` against the
    MLE-friendly weight `W(u) = Phi(eq(point, u))`. Returns the target and W as a closure."""
    challenges = transcript.samples(len(RING_MAP_SHIFTS))
    # The same map as a Frobenius sum, `Phi(a) = sum_k c_k a^(2^k)` for k < 64.
    coefficients = [reduce(mul, (f ** (2 ** (k % s)) for f, s in zip(challenges, RING_MAP_SHIFTS) if k & s), ONE) for k in range(K_BITS)]
    target = poly_eval([_phi(value, challenges) for value in s], GEN)
    return target, lambda r_prime: _ring_weight(point, r_prime, coefficients)


# Stacked opening -------------------------------------------------------------


type StackClaim = tuple[Callable[[Sequence[E]], E], E]  # the weight it puts on the stack, and the value it claims for it


def verify_stacked_opening(transcript: Transcript, root: Digest, stack_log: int, log_inv_rate: int, claims: Sequence[StackClaim]) -> None:
    """Discharge every claim on the committed stack in one opening: the same powers of one challenge
    batch the values into the target, and the weights into the basis WHIR evaluates at its terminal point.
    """
    weights, values = zip(*claims, strict=True)
    scales = powers(transcript.sample(), len(claims))
    verify_whir(transcript, stack_log, log_inv_rate, dot(scales, values), root, lambda point: dot(scales, [weight(point) for weight in weights]))


def verify_execution(bytecode: Sequence[K], public_input: Digest, proof: Proof) -> None:
    bytecode_hash = blake2s_hash(b"".join(word.to_bytes() for word in bytecode))
    iv_preimage = b"leanvm" + pack("<Q", len(R1CS_DIGEST)) + R1CS_DIGEST + bytecode_hash.value
    fiat_shamir_IV = blake2s_hash(iv_preimage)
    transcript = Transcript(proof, fiat_shamir_IV, public_input)

    # 1] memory log-size, table log-size, and log-inv-rate in WHIR
    announced = transcript.next_scalars(2 + len(TABLES))
    require(all(value.c1 == value.c2 == 0 for value in announced), "announced size has a nonzero high limb")
    log_memory = int(announced[0].c0)
    table_logs = tuple(int(value.c0) for value in announced[1 : 1 + len(TABLES)])
    log_inverse_rate = int(announced[-1].c0)
    require(1 <= log_inverse_rate <= 4, "invalid PCS inverse rate")
    layout = build_layout(bytecode, log_memory, table_logs)
    require(MIN_STACKED_LOG <= layout.stack_log <= MAX_STACKED_LOG, "committed size outside the PCS window")

    # 2] parse WHIR commitment: one Merkle root (No OOD, our PCS is only List-binding).
    root = Digest.from_halves(*transcript.next_scalars(2))

    # 3] Bus: one batched GKR over the push, pull and count trees, then the leaf decomposition, which leaves each table a degree-2 claim.
    bus = verify_bus_balance(layout, transcript)

    # 4] One batched (back-loaded) "table sumcheck" over all six tables, at the bus point, proving the target the three
    # leaf claims derive and that constraints vanish. Every table takes a disjoint range of xi powers for its constraints
    xi = transcript.sample()
    n_constraints = sum(table.n_constraints for table in TABLES)
    xi_powers = powers(xi, n_constraints + 3)  # one power per constraint, then one per bus side, shared by every table
    constraint_powers, form_powers = xi_powers[:n_constraints], xi_powers[n_constraints:]
    target = dot(form_powers, bus.totals)
    table_sumcheck_claims = table_sumcheck(layout.table_log_heights, bus.forms, constraint_powers, form_powers, bus.point, target, transcript)
    claims = [*bus.claims, *table_sumcheck_claims]

    # 5] binding the public input: each memory limb's claim is that limb's public line at the challenge, which the verifier
    # evaluates itself, so the prover sends nothing. Both public words are 128-bit, so the top limb's claim is zero.
    public_challenge = transcript.sample()
    first, second = public_input.halves()
    public_limbs = tuple(multilinear_eval(pair, [public_challenge]) for pair in ((first.c0, second.c0), (first.c1, second.c1), (first.c2, second.c2)))
    public_point = (public_challenge, *[ZERO] * (layout.placements[MEMORY_0].variables - 1))
    claims.extend(ColumnClaim(column, public_point, value) for column, value in zip((MEMORY_0, MEMORY_1, MEMORY_2), public_limbs))

    # 6] BLAKE2s validity via Flock
    flock_point, flock_s = verify_flock(BLAKE2S_R1CS_LOG_SIZE + layout.table_log_heights[OP_BLAKE2S], transcript)

    # 7] Ring-switching
    ringswitch_target, ringswitch_weight = ring_switch(flock_point, flock_s, transcript)
    # That claim is supported on q_flock's region of the stack, so its weight carries the
    # placement's selector, and it leads the batch, taking the first power.
    qflock = layout.placements[QFLOCK]
    ringswitch = (lambda x: qflock.eq_above(x) * ringswitch_weight(x[: qflock.variables]), ringswitch_target)
    verify_stacked_opening(transcript, root, layout.stack_log, log_inverse_rate, [ringswitch, *(c.on_stack(layout) for c in claims)])
    transcript.finish()


def main(argv: Sequence[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Verify a leanVM execution proof")
    parser.add_argument("bytecode", type=Path, help="stacked bytecode multilinear, little-endian 64-bit words")
    parser.add_argument("public_input", type=Path, help="256-bit public input")
    parser.add_argument("stream", type=Path, help="the proof's scalar stream, 24-byte little-endian field elements")
    parser.add_argument("merkle_openings", type=Path, help="every Merkle opening: its leaf's words, then its sibling digests")
    arguments = parser.parse_args(argv)
    try:
        encoded_bytecode = arguments.bytecode.read_bytes()
        require(len(encoded_bytecode) % 8 == 0, "bytecode is not a whole number of 64-bit words")
        bytecode = [K(int.from_bytes(encoded_bytecode[i : i + 8], "little")) for i in range(0, len(encoded_bytecode), 8)]
        proof = Proof.load(arguments.stream, arguments.merkle_openings)
        verify_execution(bytecode, Digest(arguments.public_input.read_bytes()), proof)
    except (OSError, ValueError, KeyError, VerificationError) as exc:
        parser.exit(1, f"verification failed: {exc}\n")
    print("verification succeeded")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
