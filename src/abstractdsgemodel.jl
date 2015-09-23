abstract AbstractDSGEModel

# TODO consider stacking all parameters in a single vector. Alternately, all fixed
# parameters can be added to the normal parameters vector at a (potentially negligible)
# performance hit.
Base.getindex(m::AbstractDSGEModel, i::Integer) = begin
    if i <= num_parameters(m)
        return m.parameters[i]
    elseif i <= num_parameters(m) + num_parameters_fixed(m)
        return m.parameters_fixed[i - num_parameters(m)]
    elseif i <= num_parameters(m) + num_parameters_fixed(m) + num_parameters_steady_state(m)
        return m.steady_state[i - num_parameters(m) - num_parameters_fixed(m)]
    end
end
Base.getindex(m::AbstractDSGEModel, k::Symbol) = Base.getindex(m,m.keys[k])

Base.setindex!(m::AbstractDSGEModel, value, i::Integer) = begin
    if i <= num_parameters(m)
        setindex!(m.parameters, value, i)
    elseif i <= num_parameters(m) + num_parameters_fixed(m)
        setindex!(m.parameters_fixed, value, i-num_parameters(m))
    elseif i <= num_parameters(m) + num_parameters_fixed(m) + num_parameters_steady_state(m)
        setindex!(m.steady_state, value, i - num_parameters(m) - num_parameters_fixed(m))
    end
end
Base.setindex!(m::AbstractDSGEModel, value, k::Symbol) = Base.setindex!(m,value,m.keys[k])

function Base.show{T<:AbstractDSGEModel}(io::IO, m::T)
    @printf io "Dynamic Stochastic General Equilibrium Model\n"
    @printf io "%s\n" T
    @printf io "no. states:             %i\n" num_states(m)
    @printf io "no. anticipated shocks: %i\n" num_anticipated_shocks(m)
    @printf io "no. anticipated lags:   %i\n" num_anticipated_lags(m)
    @printf io "description:\n %s\n" description(m)
end

# Number of anticipated policy shocks
num_anticipated_shocks(m::AbstractDSGEModel) = m.num_anticipated_shocks

# Padding for nant
num_anticipated_shocks_padding(m::AbstractDSGEModel) = m.num_anticipated_shocks_padding

# Number of periods back we should start incorporating zero bound expectations
# ZLB expectations should begin in 2008 Q4
num_anticipated_lags(m::AbstractDSGEModel) = m.num_anticipated_lags

# TODO: This should be set when the data are read in
# Number of presample periods
num_presample_periods(m::AbstractDSGEModel) = m.num_presample_periods

# Number of a few things that are useful apparently
num_states(m::AbstractDSGEModel)                 = length(m.endogenous_states)
num_states_augmented(m::AbstractDSGEModel)       = num_states(m) + length(m.endogenous_states_postgensys)
num_shocks_exogenous(m::AbstractDSGEModel)       = length(m.exogenous_shocks)
num_shocks_expectational(m::AbstractDSGEModel)   = length(m.expected_shocks)
num_equilibrium_conditions(m::AbstractDSGEModel) = length(m.equilibrium_conditions)
num_observables(m::AbstractDSGEModel)            = length(m.observables)
num_parameters(m::AbstractDSGEModel)             = length(m.parameters)
num_parameters_fixed(m::AbstractDSGEModel)       = length(m.parameters_fixed)
num_parameters_steady_state(m::AbstractDSGEModel)= length(m.steady_state)
num_parameters_free(m::AbstractDSGEModel)        = sum([!α.fixed for α in m.parameters])

# Paths to where input/output/results data are stored
savepath(m::AbstractDSGEModel)  = normpath(m.savepath)
inpath(m::AbstractDSGEModel)    = normpath(joinpath(m.savepath, "input_data/"))
outpath(m::AbstractDSGEModel)   = normpath(joinpath(m.savepath, "output_data/"))
tablepath(m::AbstractDSGEModel) = normpath(joinpath(m.savepath, "results/tables/"))
plotpath(m::AbstractDSGEModel)  = normpath(joinpath(m.savepath, "results/plots/"))
logpath(m::AbstractDSGEModel)   = normpath(joinpath(m.savepath, "logs/"))

# Paths to where input/output/results data are stored
savepath(m::AbstractDSGEModel)  = m.savepaths[:savepath]
inpath(m::AbstractDSGEModel)    = m.savepaths[:inpath]
outpath(m::AbstractDSGEModel)   = m.savepaths[:outpath]
tablepath(m::AbstractDSGEModel) = m.savepaths[:tablepath]
plotpath(m::AbstractDSGEModel)  = m.savepaths[:plotpath]
logpath(m::AbstractDSGEModel)   = m.savepaths[:logpath]

function createSaveDirectories{T<:AbstractString}(m::AbstractDSGEModel, savepath::T; reset_inpath::Bool=true)

    createSaveDirectories(savepath)

    paths = [(:savepath,  savepath),
             (:outpath,   joinpath(savepath, "output_data")),
             (:logpath,   joinpath(savepath, "logs")),
             (:tablepath, joinpath(savepath, "results/tables")),
             (:plotpath,  joinpath(savepath, "results/plots"))]

    if reset_inpath
        append!(paths, [(:inpath, joinpath(savepath, "input_data"))])
    else
        append!(paths, [(:inpath, inpath(m))])
    end

    m.savepaths = Dict{Symbol,AbstractString}(paths)
    
end

## Creates proper directory structure for input and output files rooted at new_savepath,
## and copies the files in `old_savepath/input_data` to `new_savepath/input_data`
function createSaveDirectories{T<:AbstractString}(m::AbstractDSGEModel, new_savepath::T, old_savepath::T; reset_inpath::Bool=true, copy_infiles::Bool=true)

    createSaveDirectories(m, new_savepath; reset_inpath=reset_inpath)

    if copy_infiles
        for file in readdir(normpath(joinpath(old_savepath, "input_data")))
            #if isfile(abspath(file))
                println(file)
                cp(abspath(joinpath(old_savepath, "input_data/$file")), inpath(m))
                old = abspath(joinpath(old_savepath, "input_data/$file"))
                new = abspath(joinpath(new_savepath, "input_data"))
                @printf "Copied %s to %s" old new
            #end
        end
    end

    return m.savepaths
end



# TODO is there a better place for these? They do depend on AbstractDSGEModel type.
function tomodel!{T<:AbstractFloat}(m::AbstractDSGEModel, values::Vector{T})
    tomodel!(values, m.parameters)
    return steadystate!(m)
end

function update!{T<:AbstractFloat}(m::AbstractDSGEModel, values::Vector{T})
    update!(m.parameters, values)
    return steadystate!(m) 
end

