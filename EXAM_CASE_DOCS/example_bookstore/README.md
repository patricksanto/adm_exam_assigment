Bookstore Example — Online Order Analysis

This is a supplementary worked example. It covers the same ADM pipeline as the bus example but uses a different dataset and makes different decisions at each phase — useful for seeing that the process applies across different contexts.

Download the full worked example: example_bookstore_full_model.pdf
The Scenario

An online bookstore wants to understand order patterns and revenue across products, genres, and time. The dataset contains orders and order items from two separate source tables.

The bookstore example is particularly useful because it shows:

A multi-source join in the intermediate model — two staging models combined with a join key
Different staging decisions — abbreviated status codes (COMPL, CANC, RETN), mixed-case genre values, and columns arriving as wrong types
Revenue as a calculated field — quantity × unit_price — and why both AVG and SUM are valid metrics depending on the grain
quantity_category as a categorical field feeding a dimension table