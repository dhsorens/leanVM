// CREDIT: https://github.com/succinctlabs/flock (flock-core), MIT OR Apache-2.0.
//! Additive NTTs (Lin-Chung-Han novel polynomial basis): [`AdditiveNttF64`], for WHIR commitments.

pub mod additive_ntt_f64;
pub use additive_ntt_f64::{AdditiveNttF64, RowSink, transpose_lane_major};
