
export marginal_likelihood, marginal_divergence, mean_marginal_likelihood

# TODO 7/2: there currently is no clear way to get RMD for any observation parameters. Should one theoretically be able to do this??

"""
Compute the (log) marginal likelihood log(p(y)) using precomputed likelihood distributions
"""
function marginal_likelihood(log_lik::Particles{T, N}) where {T, N}
    m = convert(T, N)
    -log(m) + logsumexp(log_lik.particles)
end

# for the case when nothing is marginalized
marginal_likelihood(log_lik::AbstractFloat) = log_lik

function _md_iter(y, μnum, μdenom, om::AbstractObservationModel)
    ℓnum = log_likelihood(om, μnum, y)
    ℓdenom = log_likelihood(om, μdenom, y)
    marginal_likelihood(ℓnum) - marginal_likelihood(ℓdenom)
end

# function solve_adj(lm::M, θ, prob; dekwargs...) where M <: AbstractLatentModel
#     θnew = NamedTuple{θnames}(θ)
#     _lm = M(;θnew..., θrest...)
#     _prob = de_problem(lm; dekwargs...)
#     solve(_lm; dekwargs...).u
# end

# function info_mat(lm, om, θtrue; dekwargs...)
#     x = solve(lm, θtrue; dekwargs...).u
#     O = obs_info_mat(om, x)
#     J = ForwardDiff.jacobian(p->solve_adj(lm, p, keys(θtrue); dekwargs...), vcat(values(θtrue)...))
#     return J' * O * J
# end

"""
The Restricted Marginal Divergence (RMD). `μcond` is simulations sampled from the latent process, with a quantity of interest held fixed,
and `μprior` is simulations sampled from the full prior latent process. The RMD is the difference between marginal log likelihoods of these two,
on average over data `y` originating from a true process.
"""
function marginal_divergence(
    y::Distribution, μcond::Vector{<:Param{T}}, μprior::Vector{<:Param{T}}, om::AbstractObservationModel; N=3000
) where T
    mds = zeros(T, N)
    Threads.@threads for i=1:N
        mds[i] = _md_iter(rand(y), μcond, μprior, om)
    end
    mean(mds)
end

marginal_divergence(y::VecOrMat, μcond, μprior, om; N=3000) = marginal_divergence(product_distribution(y), μcond, μprior, om; N)

function marginal_divergence(
    ϕ::Tuple, θtrue::NamedTuple, lm::LM, om::AbstractObservationModel; 
    N=3000, dekwargs...
) where {LM<:AbstractLatentModel}
    ϕtup = NamedTuple{ϕ}(map(x->get(θtrue, x, nothing), ϕ))
    μtrue = solve(lm, θtrue; dekwargs...).u
    y = observe_dist(om, μtrue)
    μcond = solve(lm, ϕtup; dekwargs...).u
    μprior = solve(lm; dekwargs...).u
    return marginal_divergence(y, μcond, μprior, om; N)
end

marginal_divergence(ϕ::Function, θtrue::NamedTuple, lm, om; N=3000, dekwargs...) = error("Passing summary functions directly not supported yet")

# uidx and F should match order in θtrue
# function approx_marginal_divergence(lm, om, θtrue, uprior, uidx, F=nothing; dekwargs...)
#     JOJ = info_mat(lm, om, θtrue; dekwargs...)
#     if F === nothing
#         Iu = JOJ
#     else
#         Iu = F' * JOJ * F
#     end
#     -0.5 * (log(inv(Iu)[uidx, uidx]) - log(2*π)) - log(uprior)
# end

"""
Compute expected log marginal likelihood, marginalizing over whatever simulations are represented by `x`, with the expectation over `y`

Could be useful e.g. if you want to compute the RMD of several variables, while reusing the calculation for the full marginal likelihood E[P(y)]

The current main problem with this (might be others) is that y would need to be presampled and the same between usages of these

Also, doing the multithreading part twice might not make this worth it in some cases
"""
# function mean_marginal_likelihood(
#     y::Vector{Particles{T, N}}, x::VecRealOrParticles{S, M}, om::AbstractObservationModel
# ) where {T, S, N, M}
#     ml_iter = y->marginal_likelihood(logpdf_particles(om, x, y))
#     bypmap(ml_iter, y) |> pmean
# end