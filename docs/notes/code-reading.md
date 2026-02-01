# **Code Reading**


!!! note
	Always have goal/objective in mind, to stay on track


## **about code navigation**

code navigation is influenced by 

- the goal
- the start-point
- the way to follow the code (flow-sensitivity, tracing-direction)

can be described in terms of

- External flow sensitivity: how execution proceeds from function to function, but not within it 

	- Control flow sensitivity
	- Data flow sensitivity 


- Tracing direction

	- Forward-tracing: to evaluate code functionality 

		start-point: beginning of function, start of program etc 
	
	- Back-tracing: to evaluate code reachability
	
		start-point: Candidate point




## **about code auditing strategies**

has 3 basic types

- Code comprehension Strategies: to understand the code

	start-point: beginning of line, function, algo, trust-boundary

	flow: forward-tracing, control/data sensitive
	

	- CC1: Trace malicious input
	- CC2: Analyze a module
	- CC3: Analyze an algorithm
	- CC4: Analyze a object/class
	- CC5: Trace black-box

- Candidate Point Strategies: 


- Design generalization strategies -> DS



## **about code auditing tactics**

- Internal flow analysis: within function
	- error-checking branches
	- pathological code-paths: functions with many small and non-terminating branches

- Subsystem and Dependency analysis
	- try to see the bigger-picture
	- look into connected subsystems / analyze dependencies

- Re-reading the code (atleast 2 passes)
	- doing multiple passes: with each pass focusing on different objective

- Desk checking
	- create table with code statements in column and variables in another

- Test cases: test edge cases
	- constraint establishment
	- input thinning


## **refer**

- book: The art of software security assessment
- book: How to read a book 
