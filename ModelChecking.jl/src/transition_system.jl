# System
# Description:
#   A file containing some of the structures needed to represent and manipulate the
#   system object for use in the KAM algorithm.

using SparseArrays, Graphs, GraphPlot

# =======
# Objects
# =======

struct TransitionSystem
    S::Vector{String}
    Act::Vector{String}
    Transitions::Vector{SparseMatrixCSC{Int,Int}}
    I::Vector{String}
    AP::Vector{String}
    LAsMatrix::SparseMatrixCSC{Int,Int}
end

# =========
# Functions
# =========

"""
TransitionSystem(n_S::Integer)
Description:
    An alternative function for defining a new transition system object.
    This implementation creates n_S arbitrary states and nothing else.
"""
function TransitionSystem(n_S::Integer)
    # Constants

    # Algorithm
    tempS::Array{String} = []
    for s in range(1,stop=n_S)
        append!(tempS,[string("s",s)])
    end

    return TransitionSystem(tempS,[], Vector{SparseMatrixCSC{Int,Int}}([]), tempS,[],sparse([],[],[]) )
end

"""
TransitionSystem(n_S::Integer,n_Act::Integer)
Description:
    Creates a transition system with:
    - n_S States
    - n_Act Actions
"""
function TransitionSystem(n_S::Integer,n_Act::Integer)
    # Constants

    # Algorithm

    #s
    tempS::Vector{String} = []
    for s_index in range(1,stop=n_S)
        append!(tempS,[string("s",s_index)])
    end

    # Create n_Act strings for Act
    tempAct::Vector{String} = []
    for act_index in range(1,stop=n_Act)
        append!(tempAct,[string("a_",act_index)])
    end

    #Create empty transition FAsMatrices
    tempTransitionsAsMatrices = Vector{SparseMatrixCSC{Int,Int}}([])
    for s_index in range(1,stop=n_S)
        push!(tempTransitionsAsMatrices,sparse([],[],[],n_Act,n_S))
    end

    # Create empty output Matrix
    
    return TransitionSystem(tempS,tempAct, tempTransitionsAsMatrices, tempS,[],sparse([],[],[]) )

end

"""
TransitionSystem(n_S::Integer,n_Act::Integer,n_AP::Integer)
Description:
    Creates a transition system with:
    - n_S States
    - n_Act Actions
    - n_AP Atomic Propositions
"""
function TransitionSystem(n_S::Integer,n_Act::Integer,n_AP::Integer)
    # Constants

    # Algorithm

    #s
    tempS::Vector{String} = []
    for s_index in range(1,stop=n_S)
        append!(tempS,[string("s",s_index)])
    end

    # Create n_Act strings for Act
    tempAct::Vector{String} = []
    for act_index in range(1,stop=n_Act)
        append!(tempAct,[string("a_",act_index)])
    end

    # Create n_AP strings for AP
    tempAP::Vector{String} = []
    for ap_index in range(1,stop=n_AP)
        append!(tempAP,[string("ap_",ap_index)])
    end

    #Create empty transition FAsMatrices
    tempTransitionsAsMatrices = Vector{SparseMatrixCSC{Int,Int}}([])
    for s_index in range(1,stop=n_S)
        push!(tempTransitionsAsMatrices,sparse([],[],[],n_Act,n_S))
    end

    # Create empty output Matrix
    
    return TransitionSystem(tempS,tempAct, tempTransitionsAsMatrices, tempS,tempAP,sparse([],[],[], n_S,n_AP) )

end



"""
find_state_index_of(name_in::String, ts_in::TransitionSystem)
Description:
    Retrieves the index of the state that has name name_in.
"""
function find_state_index_of(name_in::String, ts_in::TransitionSystem)
    # Constants

    # algorithm
    for s_index = range(1, stop=length(ts_in.S) )
        if ts_in.S[s_index] == name_in
            return s_index
        end
    end

    # if the name was not found, then return -1.
    return -1

end

"""
find_action_index_of(name_in::String, system_in::TransitionSystem)
Description:
    Retrieves the index of the ACTION that has name name_in.
"""
function find_action_index_of(name_in::String, system_in::TransitionSystem)
    # Constants

    # algorithm
    for act_index = range(1, stop=length(system_in.Act) )
        if system_in.Act[act_index] == name_in
            return act_index
        end
    end

    # if the name was not found, then return -1.
    return -1

end

"""
find_proposition_index_of(name_in::String, system_in::TransitionSystem)
Description:
    Retrieves the index of the AP that has name name_in.
"""
function find_proposition_index_of(name_in::String, system_in::TransitionSystem)
    # Constants

    # algorithm
    for ap_index = range(1, stop=length(system_in.AP) )
        if system_in.AP[ap_index] == name_in
            return ap_index
        end
    end

    # if the name was not found, then return -1.
    return -1

end

"""
Post(s::String, act::String, ts_in::TransitionSystem)
Description:
    Attempts to find the set of states that the system will transition to
    from the current state s with action act.
"""
function Post(s::String, act::String, ts_in::TransitionSystem)
    # Constants
    s_index = find_state_index_of(s,ts_in)
    act_index = find_action_index_of(act,ts_in)

    # Algorithm
    nextStateIndices = Post(s_index,act_index,ts_in) # See below for implementation of F for integers.

    nextStatesAsStrings = Array{String}([])
    for nsi_index = 1:length(nextStateIndices)
        push!(nextStatesAsStrings,ts_in.S[nextStateIndices[nsi_index]])
    end

    return nextStatesAsStrings

end

"""
Post(s_index::Integer, act_index::Integer, ts_in::TransitionSystem)
Description:
    Attempts to find the set of states that the system will transition to
    from the current state system_in.X[x_index] with input system_in.U[u_index].
"""
function Post(s_index::Integer, act_index::Integer, ts_in::TransitionSystem)::Vector{Integer}
    # Constants

    # Algorithm
    T_s = ts_in.Transitions[s_index]
    if T_s == []
        throw(DomainError("No transitions are defined for the system from the state "+string(s_index)+"."))
    end

    tempI, tempJ, tempV = findnz(T_s)
    matching_indices = findall( tempI .== act_index )

    return tempJ[ matching_indices ]

end

"""
Post(s_index::Integer, ts_in::TransitionSystem)
Description:
    Attempts to find the set of states that the system can transition to
    from the current state system_in.X[x_index] with ANY input.
"""
function Post(s_index::Integer, ts_in::TransitionSystem)
    # Constants

    # Algorithm
    temp_post = Vector{Integer}([])
    for act_index in range(1,stop=length(ts_in.Act))
        temp_post = union!(temp_post,Post(s_index,act_index,ts_in))
    end

    return temp_post

end

"""
Post(s::String, ts_in::TransitionSystem)
Description:
    Attempts to find the set of states that the system can transition to
    from the current state s with ANY input.
"""
function Post(s::String, ts_in::TransitionSystem)
    # Constants
    s_index = find_state_index_of(s,ts_in)

    # Algorithm
    temp_post_as_indices = Post(s_index,ts_in)

    # Convert temp_post_as_indices to a Vector of strings
    temp_post = Vector{String}([])
    for temp_s_index in temp_post_as_indices
        temp_post = push!(temp_post,ts_in.S[temp_s_index])
    end

    return temp_post

end

"""
Post(s_array::Vector{String}, act::String, ts_in::TransitionSystem)
Description:
    Attempts to find the set of states that the system will transition to
    from the current state (which is somewhere in s_array) with input act.
"""
function Post(s_array::Vector{String}, act::String, ts_in::TransitionSystem)
    # Constants
    act_index = find_action_index_of(act,ts_in)

    # Algorithm
    nextStateIndices = Vector{Integer}([])
    for s in s_array
        s_index = find_state_index_of(s,ts_in)
        push!(nextStateIndices,Post(s_index,act_index,ts_in)...)
    end

    nextStatesAsStrings = Array{String}([])
    for nsi_index = 1:length(nextStateIndices)
        push!(nextStatesAsStrings,ts_in.S[nextStateIndices[nsi_index]])
    end

    return nextStatesAsStrings

end

"""
Post(s_indices::Vector{Integer}, act_index::Integer, ts_in::TransitionSystem)
Description:
    Attempts to find the set of states that the system will transition to
    from the current state system_in.S[s_index] with input system_in.Act[act_index].
"""
function Post(s_indices::Vector{Integer}, act_index::Integer, ts_in::TransitionSystem)
    # Constants

    # Algorithm
    ancestorStates = Vector{String}([])

    for s_index in s_indices
        push!(ancestorStates,Post(s_index,act_index,system_in)...)
    end

    return ancestorStates

end

"""
add_transition!(ts_in::TransitionSystem,transition_in::Tuple{Int,Int,Int})
Description:
    Adds a transition to the transition system ts_in according to the tuple of indices tuple_in.
        tuple_in = (s_in,act_in,s_next_in)
"""
function add_transition!(ts_in::TransitionSystem,transition_in::Tuple{Int,Int,Int})
    # Constants
    s_in = transition_in[1]
    act_in = transition_in[2]
    s_next_in = transition_in[3]

    # Checking inputs
    check_s(s_in,ts_in)
    check_act(act_in,ts_in)
    check_s(s_next_in,ts_in)
    
    # Algorithm
    ts_in.Transitions[s_in][act_in,s_next_in] = 1
    
end

"""
add_transition!(ts_in::TransitionSystem,transition_in::Tuple{String,String,String})
Description:
    Adds a transition to the transition system ts_in according to the tuple of NAMES tuple_in.
        tuple_in = (s_in,act_in,s_next_in)
"""
function add_transition!(ts_in::TransitionSystem,transition_in::Tuple{String,String,String})
    # Constants
    s_in = transition_in[1]
    act_in = transition_in[2]
    s_next_in = transition_in[3]

    # Checking inputs

    # println(transition_in)
    
    s_index = find_state_index_of(s_in,ts_in)
    act_index = find_action_index_of(act_in,ts_in)
    s_next_index = find_state_index_of(s_next_in,ts_in)

    # Algorithm
    add_transition!(ts_in,( s_index , act_index , s_next_index ))
    
end

"""
L(s::String, ts_in::TransitionSystem)
Description:
    Attempts to find the label of the state s (if it is in the set of states).
"""
function L(s_index::Integer, ts_in::TransitionSystem)
    # Constants
    check_s(s_index,ts_in)

    # Algorithm

    # Convert temp_post_as_indices to a Vector of strings
    tempI, tempJ, tempV = findnz(ts_in.LAsMatrix)
    matching_indices = findall( tempI .== s_index )

    return tempJ[ matching_indices ]

end

"""
L(s::String, ts_in::TransitionSystem)
Description:
    Attempts to find the label of the state s (if it is in the set of states).
"""
function L(s::String, ts_in::TransitionSystem)
    # Constants
    s_index = find_state_index_of(s,ts_in)

    # Algorithm
    ap_indices = L(s_index,ts_in)

    # Collect AP's names
    temp_AP_vec = Vector{String}([])
    for temp_ap_index in ap_indices
        temp_AP_vec = push!(temp_AP_vec,ts_in.AP[temp_ap_index])
    end

    return temp_AP_vec

end

"""
check_s(s_in::Integer,ts_in::TransitionSystem)
Description:
    Checks to make sure that a possible state index is actually in the bounds of the set of states S.
"""
function check_s(s_in::Integer,ts_in::TransitionSystem)
    # Constants
    n_S = length(ts_in.S)

    # Algorithm
    if (1 > s_in) || (n_S < s_in)
        throw(DomainError("The input transition references a state " * string(s_in) * " which is not in the state space!"))
    end

    return
end

"""
check_s(s_in::String,ts_in::TransitionSystem)
Description:
    Checks to make sure that a possible state NAME is actually in the set of states S
"""
function check_s(s_in::String,ts_in::TransitionSystem)
    # Constants

    # Algorithm
    if !(s_in in ts_in.S)
        throw(DomainError("The input transition references a state " * string(s_in) * " which is not in the state space!"))
    end

    return
end

"""
check_act(act_index_in::Integer,ts_in::TransitionSystem)
Description:
    Checks to make sure that a possible action INDEX is actually in the bounds of The
    set of actions Act.
"""
function check_act(act_index_in::Integer,ts_in::TransitionSystem)
    # Constants
    n_Act = length(ts_in.Act)

    # Algorithm
    if (1 > act_index_in) || (n_Act < act_index_in)
        throw(DomainError("The input transition references a state " * string(act_index_in) * " which is not in the input space!"))
    end

    return
end

"""
check_act(act_in::String,ts_in::TransitionSystem)
Description:
    Checks to make sure that a possible action name is actually in the bounds of the
    set of all actions Act.
"""
function check_act(act_in::String,ts_in::TransitionSystem)
    # Constants

    # Algorithm
    if !(act_in in ts_in.Act)
        throw(DomainError("The input transition references a state " * string(act_in) * " which is not in the input space!"))
    end

    return
end

"""
check_AP(ap_index_in::Integer,ts_in::TransitionSystem)
Description:
    Checks to make sure that a possible atomic proposition INDEX is actually in the bounds of The
    set of propositions AP.
"""
function check_AP(ap_index_in::Integer,ts_in::TransitionSystem)
    # Constants
    n_AP = length(ts_in.AP)

    # Algorithm
    if (1 > ap_index_in) || (n_AP < ap_index_in)
        throw(DomainError("The atomic proposition at index " * string(ap_index_in) * " is not in the atomic proposition set!"))
    end

    return
end

"""
check_AP(ap_in::String,ts_in::TransitionSystem)
Description:
    Checks to make sure that a possible atomic proposition name is actually in the 
    set of all atomic propositions AP.
"""
function check_AP(ap_in::String,ts_in::TransitionSystem)
    # Constants

    # Algorithm
    if !(ap_in in ts_in.AP)
        throw(DomainError("The atomic proposition \"" * string(ap_in) * "\" is not in the set of all atomic propositions!"))
    end

    return
end

"""
add_label!(ts_in::TransitionSystem,label_in::Tuple{Int,Int})
Description:
    Adds a label to the transition system ts_in according to the tuple of indices tuple_in.
        label_in = (s_in,AP_in)
"""
function add_label!(ts_in::TransitionSystem,label_in::Tuple{Int,Int})
    # Constants
    s_in = label_in[1]
    AP_in = label_in[2]

    # Checking inputs
    check_s(s_in,ts_in)
    check_AP(AP_in,ts_in)
    
    # Algorithm
    ts_in.LAsMatrix[s_in,AP_in] = 1
    
end

"""
add_label!(ts_in::TransitionSystem,label_in::Tuple{String,String})
Description:
    Adds a transition to the transition system ts_in according to the tuple of NAMES tuple_in.
        label_in = (s_in,AP_in)
"""
function add_label!(ts_in::TransitionSystem,label_in::Tuple{String,String})
    # Constants
    s_in = label_in[1]
    AP_in = label_in[2]

    # println(label_in)
    
    s_index = find_state_index_of(s_in,ts_in)
    ap_index = find_proposition_index_of(AP_in,ts_in)

    # Algorithm
    add_label!(ts_in,( s_index , ap_index ))
    
end

"""
get_vending_machine_system()
Description:
    Returns the beverage vending machine example.
"""
function get_vending_machine_system()
    # Constants
    state_names = ["pay","select","get_beer","get_soda"]
    action_names = ["N/A"]
    AP_names = ["pay","select","getting_drink"]

    # Algorithm
    system_out = TransitionSystem(length(state_names),length(action_names),length(AP_names))
    
    # Add state names
    for state_index in range(1,stop=length(state_names))
        system_out.S[state_index] = state_names[state_index]
    end

    # Add Input Names
    for input_index in range(1,stop=length(action_names))
        system_out.Act[input_index] = action_names[input_index]
    end

    # Add Output Names
    for output_index in range(1,stop=length(AP_names))
        system_out.AP[output_index] = AP_names[output_index]
    end

    # Create transitions
    add_transition!(system_out,("pay","N/A","select"))
    add_transition!(system_out,("select","N/A","get_beer"))
    add_transition!(system_out,("select","N/A","get_soda"))
    add_transition!(system_out,("get_beer","N/A","pay"))
    add_transition!(system_out,("get_soda","N/A","pay"))

    # Create Outputs
    add_label!(system_out,("pay","pay"))
    add_label!(system_out,("select","select"))
    add_label!(system_out,("get_beer","getting_drink"))
    add_label!(system_out,("get_soda","getting_drink"))

    return system_out
end

"""
get_philsopher_system(phil_i::Int,num_phil::Int)
Description:
    Returns the transition system of the phil_i-th philosopher (starting from 0)
    from the dining philosophers example. There are num_phil philosophers in total.
"""
function get_philsopher_system(phil_i::Int,num_phil::Int)
    # Input processing
    if phil_i < 0
        throw(DomainError("The input philosopher index (" * string(phil_i) * ") is less than zero! Not allowed!"))
    end

    if phil_i >= num_phil
        throw(DomainError("The input philosopher index (" * string(phil_i) * ") is greater than or equal to num_phil (" * string(num_phil)  *")! phil_i must be in [0,num_phil)!"))
    end
    
    # Constants
    state_names = [
        "think",
        "wait for left stick",
        "wait for right stick",
        "eat",
        "return the left stick",
        "return the right stick"
    ]

    if phil_i == 0
        action_names = [
            "request_{"*string(num_phil-1)*","*string(phil_i)*"}",
            "request_{"*string(phil_i)*","*string(phil_i)*"}" ,
            "release_{"*string(num_phil-1)*","*string(phil_i)*"}",
            "release_{"*string(phil_i)*","*string(phil_i)*"}" 
        ]
    else
        action_names = [
            "request_{"*string(phil_i-1)*","*string(phil_i)*"}",
            "request_{"*string(phil_i)*","*string(phil_i)*"}" ,
            "release_{"*string(phil_i-1)*","*string(phil_i)*"}",
            "release_{"*string(phil_i)*","*string(phil_i)*"}" 
        ]
    end

    AP = ["has 0 chopsticks","has 1 chopstick","has 2 chopsticks"]

    # Algorithm
    ts_out = TransitionSystem(length(state_names),length(action_names),length(AP))

    # Add state names
    for state_index in range(1,stop=length(state_names))
        ts_out.S[state_index] = state_names[state_index]
    end

    # Add Input Names
    for input_index in range(1,stop=length(action_names))
        ts_out.Act[input_index] = action_names[input_index]
    end

    # Add Action Names
    for ap_index in range(1,stop=length(AP))
        ts_out.AP[ap_index] = AP[ap_index]
    end

    # Create transitions
    add_transition!(ts_out,("think",action_names[1],"wait for left stick"))
    add_transition!(ts_out,("think",action_names[2],"wait for right stick"))
    add_transition!(ts_out,("wait for left stick",action_names[2],"eat"))
    add_transition!(ts_out,("wait for right stick",action_names[1],"eat"))
    add_transition!(ts_out,("eat",action_names[3],"return the left stick"))
    add_transition!(ts_out,("eat",action_names[4],"return the right stick"))
    add_transition!(ts_out,("return the left stick",action_names[4],"think"))
    add_transition!(ts_out,("return the right stick",action_names[3],"think"))

    # Create Labels
    for state_index in range(1,stop=length(state_names))
        s_i = ts_out.S[state_index]
        # Depending on the value of the state's name, we will assign a label
        if contains(s_i,"think") # Thinking philosopher has 0 chopsticks
            add_label!(ts_out,(s_i,AP[1]))
        end

        if contains(s_i,"wait") || contains(s_i,"return") # Waiting philosopher or Returning philosopher has 1 chopstick
            add_label!(ts_out,(s_i,AP[2]))
        end

        if s_i == "eat" # Eating philosopher has 2 chopsticks
            add_label!(ts_out,(s_i,AP[3]))
        end
    end

    return ts_out
end

"""
to_graph(ts_in::TransitionSystem)
Description:
    Converts the given transition system to a graph object from Graphs library.
Usage:
    ts_as_graph = to_graph(ts_in)
    state_graph1 = to_graph(ts1)
Notes:
    This can also be thought of as converting the transition system to a state graph.
"""
function to_graph(ts_in::TransitionSystem)
    # Constants
    n_S = length(ts_in.S)

    # Algorithm

    # Create a graph
    ts_as_graph = DiGraph(n_S)

    # Iterate through every state's transition Matrix
    for s_index in range(1,stop=n_S)
        # Extract all nonzero transitions
        post_s = Post(s_index,ts_in)

        # Add edges for each element in post_s
        for s_next_ind in post_s
            add_edge!(ts_as_graph,s_index,s_next_ind)
        end
    end

    return ts_as_graph

end

"""
plot(ts_in::TransitionSystem)
Description:

"""
function plot(ts_in::TransitionSystem)
    # Constants

    # Algorithm

    # Convert to Graph
    ts_as_graph = to_graph(ts_in)

    # Get all edges and label them
    num_nodes = length(ts_in.S)
    edge_labels = Vector{String}([])
    for src_index in range(1,stop=num_nodes)
        for dest_index in ts_as_graph.fadjlist[src_index]
            # Find the actions that lead to this transition
            T_s = ts_in.Transitions[src_index]
            tempActions, tempJ, tempV = findnz(T_s)
            matching_action_indices = tempActions[findall( tempJ .== dest_index )] # Get all action indices that lead to the transition from src_index to dest_index

            # Create label by iterating through each matching action
            temp_label = string("")
            for action_index in matching_action_indices
                temp_label = string(temp_label,ts_in.Act[action_index])

                if action_index != last(matching_action_indices)
                    temp_label = string(temp_label,string(","))
                end
            end
            
            push!(edge_labels,temp_label)
        end
    end

    return gplot(ts_as_graph,
                    nodelabel=ts_in.S,
                    edgelabel=edge_labels)

end