# luagraph

Please comply with the License :)

luagraph is a primitive graph representation library for representing, manipulating and storing graphs.

LuaGraph lets you
1. Create graphs
2. Add nodes to graphs with different values (primitives or complex)
3. Add edges between the nodes with different values (primitives or complex)
4. Serialize and deserialize your graphs

LuaGraph is intended as a foundation that you can build more complex behaviour on top of. The long term goal is for this to be a performant, extensible and easy to use yet hard to misuse library.

We currently only support Undirected Graphs (via luagraph.UndirectedGraph), in the future it would be nice to add:
1. Directed graphs
2. Directed acyclic graphs (DAGs)

There is no formal documentation as of yet, but the [UndirectedGraph](https://github.com/intUnderflow/luagraph/blob/main/luagraph/UndirectedGraph/init.lua) source code has comments on each public method.

This project follows some style rules I use when programming in Lua which is that:
1. All instance properties are private regardless of name
2. All instance methods that begin with _ are private