# path_test.jl
# Description:
#   This file defines several tests for the Path object defined in path.jl.

import Test
import SparseArrays
using Test, Cairo, Compose

include("../src/ModelChecking.jl")

"""
Test 1:
Verify that the empty System can be created using default constructor.
"""

@testset "1: CreateFinitePath() tests" begin
    sys1 = get_vending_machine_system() # Create system

    pathLength1 = 10
    pi1 = CreateFinitePath(sys1,pathLength1)

    @test length(pi1) == pathLength1
    for i in range(1,stop=pathLength1-1,step=1)
        s_i = pi1[i]
        s_ip1 = pi1[i+1]
        @test s_ip1 in Post(s_i,sys1)
    end

    # Test a length one path
    pi2 = CreateFinitePath(sys1,1)
    @test length(pi2) == 1

    # Test a bad length argument
    try
        pi3 = CreateFinitePath(sys1,0)
        @test false
    catch err
        @test err.msg == "The value of n must be greater than or equal to one (1). Received 0."
    end
end