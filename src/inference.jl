## Methods for posterior approximation θ∣y

# function mle_optim(data, pdist::AbstractDEParamDistribution, likelihood=Poisson; names=keys(random_vars(pdist)), dekwargs...)
#     prob = de_problem(typeof(pdist); dekwargs...)
#     f = θ -> log_likelihood(data, prob, θ, likelihood, names)
#     init = (getfield(pdist, k) for k ∈ names)
#     init_float = [p isa Distribution ? rand(p) : p for p ∈ init]
#     optimize(f, init_float, BFGS())
# end


# #= Methods for importance sampling =#

# # _logweight(y, u, jointlik::Function) = logpdf(jointlik(u), y)
# _logweight(y, dist) = @inbounds logpdf(dist, y)

# # function _logweight(y, g, gx; lf, pd, gd=pd)
# #     logpdf(lf(gx), y) + logpdf(pd, g) - logpdf(gd, g)
# # end

# function _logweight(y, g, ld, pd, gd)
#     @inbounds logpdf(ld, y) + logpdf(pd, g) - logpdf(gd, g)
# end

# """
# Compute numerically stable, normalized importance weights given a sampling distribution 𝐺(𝜃)

# If any keywords missing, assume 𝐺(𝜃) = 𝑃(𝜃) and use the simplified formula
# """
# function importance_weights(
#     data, likdists::Vector{T}; 
#     gsamples=nothing, pri_dist=nothing, gdist=nothing
# ) where T <: Distribution
#     @assert size(data) == size(likdists[1])
#     simple = (gsamples === nothing) | (pri_dist === nothing) | (gdist === nothing)
#     ℓW = simple ? map(p->_logweight(data, p), likdists) : map(zip(gsamples, likdists)) do (θg, ld)
#         _logweight(data, θg, ld, pri_dist, gdist)
#     end
#     M = maximum(ℓW)
#     W̃ = exp.(ℓW .- M)
#     W̃ / sum(W̃) # normalize weights
# end

# """
# Compute Ê(θ∣y) using (normalized) importance weights W
# """
# function importance_mean(W, gsamples)
#     mapreduce((x, y)->x .* y, .+, gsamples, W)
# end

# function importance_mean(W, gsamples::Vector{T}) where T <: NamedTuple
#     NamedTuple{keys(gsamples[1])}(importance_mean(W, values.(gsamples)))
# end

# """
# Effective sample size for (normalized) importance weights W
# """
# importance_ess(W) = 1 / sum(x->x^2, W)



# function marginal_likelihood(data, sim::EnsembleSolution, likelihood::Function)
#     map(x->pdf(likelihood(u), data), sim) |> mean
# end