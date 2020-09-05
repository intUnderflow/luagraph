local HttpService = game:GetService("HttpService")
local TestEZ = require(script.Parent.Parent.Parent.TestEZ)

local UndirectedGraph = require(script.Parent)

local NAUGHTY_STRINGS = HttpService:JSONDecode(
    HttpService:GetAsync(
        "https://raw.githubusercontent.com/intUnderflow/big-list-of-naughty-strings/master/blns.json"
    )
)
local TYPES = {
    ["nil"] = {
        nil
    },
    boolean = {
        true,
        false
    },
    number = {
        4,
        1.58509181,
        math.pi,
        math.huge,
        -6,
        0,
        -19.15851,
        -math.huge
    },
    string = NAUGHTY_STRINGS,
    ["function"] = {
        function() end, -- userspace function
        wait -- CFunction / yielding function
    },
    table = {
        {
            "hello", "this", "is", "an", "array"
        },
        {
            1, 2, 3, 4, 5
        },
        {
            1, 5, "mixed", 7, "table", game
        },
        {
            [2] = 6,
            [7] = 1,
            [3] = "mixed dictionary"
        }
    },
    instance = {
        Instance.new("Part"), -- not RobloxLocked, changeable instance
        game, -- not-RobloxLocked, unchangeable instance
        -- game:GetService("CoreGui") -- RobloxLocked instance, currently not available because expect does a comparison which causes an error
    }
}

return function()
    describe("UndirectedGraph", function()

        describe(".new", function()
            it("should return an undirected graph when .new() is called", function()
                expect(UndirectedGraph.new() ~= nil).to.equal(true)
            end)
        end)

        describe(":hasNode", function()

            it("should return false for a nonexistant node", function()
                local graph = UndirectedGraph.new()
                expect(graph:hasNode(1)).to.equal(false)
            end)

            it("should return true for an existing node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode()
                expect(graph:hasNode(nodeId)).to.equal(true)
            end)

        end)

        describe(":addNode", function()

            local graph = UndirectedGraph.new()
            local nodeId = graph:addNode(nil)

            it("should return an ID when adding a node", function()
                expect(nodeId~=nil).to.equal(true)
            end)

            it("should return a number as the node ID", function()
                expect(type(nodeId)).to.equal("number")
            end)

            for typeName, typeList in pairs(TYPES) do

                it(("should create nodes with %s values"):format(typeName), function()

                    for key, value in ipairs(typeList) do
                    
                        local graph = UndirectedGraph.new()
                        local nodeId = graph:addNode(value)
                        expect(graph:getNodeValue(nodeId)).to.equal(value)

                    end

                end)

            end

        end)

        describe(":getNodeValue", function()

            -- most behaviour tested in :addNode
            it("should error for nodes that do not exist", function()
                local graph = UndirectedGraph.new()
                expect(function()
                    graph:getNodeValue(1)
                end).to.throw()
            end)

        end)

        -- :getNodeEdges tested in

        describe(":editNodeValue", function()

            it("should error if the node does not exist", function()
                local graph = UndirectedGraph.new()
                expect(function()
                    graph:editNodeValue(1, 2)
                end).to.throw()
            end)
            
            it("should mutate the value of a node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                graph:editNodeValue(nodeId, 2)
                expect(graph:getNodeValue(nodeId)).to.equal(2)
            end)

            it("should allow setting the node value to nil", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                graph:editNodeValue(nodeId, nil)
                expect(graph:getNodeValue(nodeId)).to.equal(nil)
            end)

        end)

        describe(":removeNode", function()

            it("should error for nodes that do not exist", function()
                local graph = UndirectedGraph.new()
                expect(function()
                    graph:removeNode(1)
                end).to.throw()
            end)

            it("should remove a node from the graph such that :hasNode reports it no longer exists", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                graph:removeNode(nodeId)
                expect(graph:hasNode(nodeId)).to.equal(false)
            end)

            it("should remove the edges from a removed node to other nodes", function()
                local graph = UndirectedGraph.new()
                local nodeToRemove = graph:addNode(1)
                local nodeWithEdge = graph:addNode(2)
                graph:addEdge(nodeToRemove, nodeWithEdge, 3)
                graph:removeNode(nodeToRemove)
                expect(#graph:getNodeEdges(nodeWithEdge)).to.equal(0)
            end)

        end)

        describe(":hasEdge", function()

            it("should error if one of the nodes does not exist", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:hasEdge(nodeId, 16)
                end).to.throw()
                expect(function()
                    graph:hasEdge(16, nodeId)
                end).to.throw()
            end)

            it("should error if attempting to test whether there is an edge between the same node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:hasEdge(nodeId, nodeId)
                end).to.throw()
            end)

            it("should report false for two unconnected nodes", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                expect(graph:hasEdge(node1, node2)).to.equal(false)
            end)

            it("should report true for two connected nodes", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(graph:hasEdge(node1, node2)).to.equal(true)
                expect(graph:hasEdge(node2, node1)).to.equal(true)
            end)
            
            it("should report false for two nodes that were connected but are now not connected", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                graph:removeEdge(node1, node2)
                expect(graph:hasEdge(node1, node2)).to.equal(false)
                expect(graph:hasEdge(node2, node1)).to.equal(false)
            end)

        end)

        describe(":addEdge", function()

            it("should error if one of the nodes does not exist", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:addEdge(nodeId, 16)
                end).to.throw()
            end)

            it("should error if attempting to add an edge between the same node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:addEdge(nodeId, nodeId)
                end).to.throw()
            end)

            it("should create an edge between two nodes", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(graph:hasEdge(node1, node2)).to.equal(true)
            end)

            it("should error if attempting to create an edge that already exists", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(function()
                    graph:addEdge(node1, node2)
                end).to.throw()
                expect(function()
                    graph:addEdge(node2, node1)
                end).to.throw()
            end)

            it("should create an edge with a given value", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                local value = HttpService:GenerateGUID(false)
                graph:addEdge(node1, node2, value)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value)
            end)

        end)

        describe(":removeEdge", function()

            it("should error if one of the nodes does not exist", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:removeEdge(nodeId, 16)
                end).to.throw()
            end)

            it("should error if attempting to remove an edge between the same node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:removeEdge(nodeId, nodeId)
                end).to.throw()
            end)

            it("should remove an edge that exists between two nodes", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                graph:removeEdge(node1, node2)
                expect(graph:hasEdge(node1, node2)).to.equal(false)
            end)

            it("should error if no edge exists between the given nodes", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                expect(function()
                    graph:removeEdge(node1, node2)
                end).to.throw()
            end)

        end)

        describe(":getEdgeValue", function()

            it("should error if one of the nodes does not exist", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:getEdgeValue(nodeId, 16)
                end).to.throw()
            end)

            it("should error if attempting to access an edge to the same node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:getEdgeValue(nodeId, nodeId)
                end).to.throw()
            end)

            it("should error if the edge does not exist", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                expect(function()
                    graph:getEdgeValue(node1, node2)
                end).to.throw()
            end)

            it("should not error, but return nil when the edge value is nil", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2, nil)
                expect(graph:getEdgeValue(node1, node2)).to.equal(nil)
            end)

            it("should return the value for a given edge", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                local value = HttpService:GenerateGUID(false)
                graph:addEdge(node1, node2, value)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value)
            end)

            it("should error if an edge existed but was then removed", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                graph:removeEdge(node1, node2)
                expect(function()
                    graph:getEdgeValue(node1, node2)
                end).to.throw()
            end)

            it("should return the updated value when an edge is updated", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                local value1 = HttpService:GenerateGUID(false)
                local value2 = HttpService:GenerateGUID(false)
                graph:addEdge(node1, node2, value1)
                graph:editEdge(node1, node2, value2)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value2)
            end)

        end)

        describe(":editEdge", function()

            it("should error if the edge does not exist", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                expect(function()
                    graph:editEdge(node1, node2)
                end).to.throw()
            end)

            it("should error if attempting to access an edge to the same node", function()
                local graph = UndirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:editEdge(nodeId, nodeId)
                end).to.throw()
            end)

            it("should permit changing the value of an existing edge", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                local value = HttpService:GenerateGUID(false)
                graph:editEdge(node1, node2, value)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value)
            end)

            it("should permit setting the value of an existing edge to nil (but the edge should still exist)", function( )
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2, HttpService:GenerateGUID(false))
                graph:editEdge(node1, node2, nil)
                expect(graph:getEdgeValue(node1, node2)).to.equal(nil)
            end)

        end)


        describe(":addOrEditEdge", function()

            -- generally tested already by :addEdge and :editEdge, just need to test behaviour for picking which method

            it("should use :addEdge if no edge exists", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                local value = HttpService:GenerateGUID(false)
                graph:addOrEditEdge(node1, node2, value)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value)
            end)

            it("should use :editEdge if an edge exists", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2, HttpService:GenerateGUID(false))
                local value = HttpService:GenerateGUID(false)
                graph:addOrEditEdge(node1, node2, value)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value)
            end)

        end)

        describe(":serialize", function()

            -- TODO: More challenging example graphs for :serialize (perhaps fuzz testing, also we should take advantage of the TYPES table)

            -- TODO: Serializability test
            --[[
            it("should fail if any of the node values are not serializable", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(game)
                expect(function()
                    graph:serialize()
                end).to.throw()
            end)

            it("should fail if any of the edge values are not serializable", function()
                local graph = UndirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2, game)
                expect(function()
                    graph:serialize()
                end).to.throw()
            end)
            ]]

            it("should return a string if the graph is serializable, which when passed to .deserialize returns the graph", function()
                local graph = UndirectedGraph.new()

                local node1Value = HttpService:GenerateGUID(false)
                local node2Value = HttpService:GenerateGUID(false)
                local node3Value = HttpService:GenerateGUID(false)
                local edgeValue = HttpService:GenerateGUID(false)

                local node1 = graph:addNode(node1Value)
                local node2 = graph:addNode(node2Value)
                local node3 = graph:addNode(node3Value)
                graph:addEdge(node1, node2, edgeValue)
                
                local serializedGraph = graph:serialize()

                local deserializedGraph = UndirectedGraph.deserialize(serializedGraph)

                expect(deserializedGraph:getNodeValue(node1)).to.equal(node1Value)
                expect(deserializedGraph:getNodeValue(node2)).to.equal(node2Value)
                expect(deserializedGraph:getNodeValue(node3)).to.equal(node3Value)
                expect(deserializedGraph:getEdgeValue(node1, node2)).to.equal(edgeValue)
            end)
             
            it("should not accept arbitrary JSON", function()
                local arbitraryJSON = HttpService:JSONEncode({
                    type = "hello",
                    data = {
                        "world"
                    }
                })
                expect(function()
                    UndirectedGraph.deserialize(arbitraryJSON)
                end).to.throw()
            end)

        end)

    end)
    
end