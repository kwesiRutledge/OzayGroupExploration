# path.jl
# Description:
#   A file containing some of the structures needed to represent and manipulate the
#   Trace object of a model checking algorithm.

const FinitePath = Vector{String}

struct InfinitePath
    FinitePrefix::FinitePath
    RepeatingSuffix::FinitePath
end

"""
CreateFinitePath
Description:
    Creates a path of length n that is valid given the transition system ts_in.
"""
function CreateFinitePath(ts_in::TransitionSystem, n::Integer) FinitePath
    # Create container to hold the path.
    pi_out = FinitePath([])

    # Check n
    if n < 1
        throw(
            ErrorException(string("The value of n must be greater than or equal to one (1). Received ",n,"."))
        )
    end

    # Create the initial condition
    s0 = rand(ts_in.S)
    i = 0
    push!(pi_out,s0)

    # Collect n-1 states that follow s_i
    for i in range(1,stop=n-1,step=1)
        # Get s_i
        s_i = pi_out[length(pi_out)]

        Post_i = Post(s_i,ts_in)
        if length(Post_i) == 0 
            throw(
                ErrorException("The post of state " + s_i + " is the empty set! Cannot extend the path longer than " + string(i) + ".")
            )
        end

        s_ip1 = rand(Post_i)
        push!(pi_out,s_ip1)
    end

    return pi_out
end

function check( pi::FinitePath, ts_in::TransitionSystem)
    """
    check
    Description:
        Checks to see if the transitions provided in 
    """
    
    # Checking all of the transitions are valid
    if length(pi) > 1
        for pi_index in range(1,length(pi)-1)
            # Get the current state and then the next one
            s_i = pi[pi_index]
            s_ip1 = pi[pi_index+1]
            if !(s_ip1 in Post(s_i,ts_in))
                throw(
                    ErrorException("The transition from state " + s_i + " to state " + s_ip1 + " does not exist")
                    )
            end

        end
    end

end