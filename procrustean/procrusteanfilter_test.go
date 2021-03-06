package procrustean

import (
	"testing"
)

func TestProcrusteanFilter_GetProcrusteanFilter1(t *testing.T) {
	// Create Basic PF
	pf1, err := GetProcrusteanFilter(
		[]string{"w0", "w1", "w2", "w3", "w4", "w5", "w6", "w7", "w8", "w9"},
		[]string{"w0"},
		[]string{"a", "b", "c", "e", "f", "g", "h", "o", "p", "q", "r"},
		map[string]map[string][]string{
			"w0": map[string][]string{
				"w1": []string{"o"},
				"w2": []string{"p"},
				"w3": []string{"q"},
				"w4": []string{"r"},
			},
			"w1": map[string][]string{
				"w5": []string{"e"},
				"w9": []string{"b"},
			},
			"w2": map[string][]string{
				"w2": []string{"b"},
				"w8": []string{"f"},
				"w9": []string{"a"},
			},
			"w3": map[string][]string{
				"w3": []string{"c"},
				"w7": []string{"f"},
			},
			"w4": map[string][]string{
				"w4": []string{"a"},
				"w6": []string{"g"},
				"w9": []string{"c"},
			},
			"w5": map[string][]string{
				"w9": []string{"g"},
			},
			"w6": map[string][]string{
				"w4": []string{"g"},
			},
			"w7": map[string][]string{
				"w9": []string{"h"},
			},
			"w8": map[string][]string{
				"w2": []string{"h"},
			},
			"w9": map[string][]string{},
		},
		[]string{"o1", "o2", "o3", "o4", "o5"},
		map[string][]string{
			"w0": []string{"o4"},
			"w1": []string{"o1"},
			"w2": []string{"o1"},
			"w3": []string{"o1"},
			"w4": []string{"o1"},
			"w5": []string{"o2"},
			"w6": []string{"o2"},
			"w7": []string{"o3"},
			"w8": []string{"o3"},
			"w9": []string{"o5"},
		},
	)

	if err != nil {
		t.Errorf("There was an issue creating the Procrustean Filter: %v", err.Error())
	}

	if len(pf1.V) != 10 {
		t.Errorf("Expected for 10 states to be in Procrustean filter but received %v.", len(pf1.V))
	}
}

func ProcrusteanFilter_GetBasic1() (ProcrusteanFilter, error) {
	// Create Basic PF
	pf1, err := GetProcrusteanFilter(
		[]string{"w0", "w1", "w2", "w3", "w4", "w5", "w6", "w7", "w8", "w9"},
		[]string{"w0"},
		[]string{"a", "b", "c", "e", "f", "g", "h", "o", "p", "q", "r"},
		map[string]map[string][]string{
			"w0": map[string][]string{
				"w1": []string{"o"},
				"w2": []string{"p"},
				"w3": []string{"q"},
				"w4": []string{"r"},
			},
			"w1": map[string][]string{
				"w5": []string{"e"},
				"w9": []string{"b"},
			},
			"w2": map[string][]string{
				"w2": []string{"b"},
				"w8": []string{"f"},
				"w9": []string{"a"},
			},
			"w3": map[string][]string{
				"w3": []string{"c"},
				"w7": []string{"f"},
			},
			"w4": map[string][]string{
				"w4": []string{"a"},
				"w6": []string{"e"},
				"w9": []string{"c"},
			},
			"w5": map[string][]string{
				"w9": []string{"g"},
			},
			"w6": map[string][]string{
				"w4": []string{"g"},
			},
			"w7": map[string][]string{
				"w9": []string{"h"},
			},
			"w8": map[string][]string{
				"w2": []string{"h"},
			},
			"w9": map[string][]string{},
		},
		[]string{"o1", "o2", "o3", "o4", "o5"},
		map[string][]string{
			"w0": []string{"o4"},
			"w1": []string{"o1"},
			"w2": []string{"o1"},
			"w3": []string{"o1"},
			"w4": []string{"o1"},
			"w5": []string{"o2"},
			"w6": []string{"o2"},
			"w7": []string{"o3"},
			"w8": []string{"o3"},
			"w9": []string{"o5"},
		},
	)

	return pf1, err
}

/*
TestProcrusteanFilter_IsDeterministic1
Description:
	Tests to see if the system correctly identifies that the example system 1 is deterministic.
*/
func TestProcrusteanFilter_IsDeterministic1(t *testing.T) {
	// Constants
	pf0 := GetPFilter1()

	// Algorithm
	if !pf0.IsDeterministic() {
		t.Errorf("The function IsDeterministic() does not think that pf0 is deterministic, when it is!")
	}
}

/*
TestProcrusteanFilter_IsDeterministic2
Description:
	Tests to see if the system correctly identifies that the example system 3 is NOT deterministic.
*/
func TestProcrusteanFilter_IsDeterministic2(t *testing.T) {
	// Constants
	pf0 := GetPFilter3()

	// Algorithm
	if pf0.IsDeterministic() {
		t.Errorf("The function IsDeterministic() thinks that pf0 is deterministic, but it is not!")
	}
}

/*
TestProcrusteanFilter_ToCompatibilityGraph1
Description:
	Creates the CompatibilityGraph for Example 1 which should contain no edges (I think).
*/
func TestProcrusteanFilter_ToCompatibilityGraph1(t *testing.T) {
	// Constants
	pf0 := GetPFilter1()

	// Algorithm
	cg0 := pf0.ToCompatibilityGraph()

	if len(cg0.E) != 2 {
		for _, edge := range cg0.E {
			t.Errorf("[ %v , %v ]", edge[0], edge[1])
		}
		t.Errorf("The number of edges in cg0 is nonzero (%v edges found)!", len(cg0.E))
	}

}

/*
TestProcrusteanFilter_ToCompatibilityGraph2
Description:
	Creates the CompatibilityGraph for Example 1 which should contain one edges (I think).
*/
func TestProcrusteanFilter_ToCompatibilityGraph2(t *testing.T) {
	// Constants
	pf0 := GetPFilter4()

	// Algorithm
	cg0 := pf0.ToCompatibilityGraph()

	if len(cg0.E) != 1 {
		t.Errorf("The number of edges in cg0 is not 1 (%v edges found)!", len(cg0.E))
	}

}

/*
TestProcrusteanFilter_ToCompatibilityGraph3
Description:
	Creates the CompatibilityGraph for Example 5 which should contain 4 edges (I think).
*/
func TestProcrusteanFilter_ToCompatibilityGraph3(t *testing.T) {
	// Constants
	pf0 := GetPFilter5()

	// Algorithm
	cg0 := pf0.ToCompatibilityGraph()

	if len(cg0.E) != 4 {
		t.Errorf("The number of edges in cg0 is not 4 (%v edges found)!", len(cg0.E))
	}

}
