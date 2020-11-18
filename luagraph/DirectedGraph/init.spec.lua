--luagraph
--Copyright (C) 2020 Lucy Sweet
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License
--along with this program.  If not, see <https://www.gnu.org/licenses/>.

local HttpService = game:GetService("HttpService")
local DirectedGraph = require(script.Parent)

return function()
    describe("DirectedGraph", function()

        describe(".deserialize", function()

            it("should return a string if the graph is serializable, which when passed to .deserialize returns the graph", function()
                local graph = DirectedGraph.new()

                local node1Value = HttpService:GenerateGUID(false)
                local node2Value = HttpService:GenerateGUID(false)
                local node3Value = HttpService:GenerateGUID(false)
                local edgeValue = HttpService:GenerateGUID(false)

                local node1 = graph:addNode(node1Value)
                local node2 = graph:addNode(node2Value)
                local node3 = graph:addNode(node3Value)
                graph:addEdge(node1, node2, edgeValue)
                
                local serializedGraph = graph:serialize()

                local deserializedGraph = DirectedGraph.deserialize(serializedGraph)

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
                    DirectedGraph.deserialize(arbitraryJSON)
                end).to.throw()
            end)

        end)

        describe(":addEdge", function()

            it("should error if one of the nodes does not exist", function()
                local graph = DirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:addEdge(nodeId, 16)
                end).to.throw()
            end)

            it("should error if attempting to add an edge between the same node", function()
                local graph = DirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:addEdge(nodeId, nodeId)
                end).to.throw()
            end)

            it("should create an edge between two nodes", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(graph:hasEdge(node1, node2)).to.equal(true)
            end)

            it("should error if attempting to create an edge that already exists", function()
                local graph = DirectedGraph.new()
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
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                local value = HttpService:GenerateGUID(false)
                graph:addEdge(node1, node2, value)
                expect(graph:getEdgeValue(node1, node2)).to.equal(value)
            end)

            it("should create an edge with the correct direction", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(graph:getEdgeDirection(node1, node2)).to.equal(node2)
            end)

        end)

        describe(":getEdgeDirection", function()

            it("should error if one of the nodes does not exist", function()
                local graph = DirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:getEdgeDirection(nodeId, 16)
                end).to.throw()
            end)

            it("should error if attempting to access an edge to the same node", function()
                local graph = DirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:getEdgeDirection(nodeId, nodeId)
                end).to.throw()
            end)

            it("should error if the edge does not exist", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                expect(function()
                    graph:getEdgeDirection(node1, node2)
                end).to.throw()
            end)

            it("should return the direction for a given edge", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(graph:getEdgeDirection(node1, node2)).to.equal(node2)
            end)

            it("should error if an edge existed but was then removed", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                graph:removeEdge(node1, node2)
                expect(function()
                    graph:getEdgeDirection(node1, node2)
                end).to.throw()
            end)

            it("should return the updated value when an edge direction is updated", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                graph:setEdgeDirection(node1, node2, node1)
                expect(graph:getEdgeDirection(node1, node2)).to.equal(node1)
            end)

        end)

        describe(":setEdgeDirection", function()

            it("should error if no new direction is supplied", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(function()
                    graph:setEdgeDirection(node1, node2, nil)
                end).to.throw()
            end)

            it("should error if a direction supplied is not a node that is connected to the edge", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                local node3 = graph:addNode(3)
                expect(function()
                    graph:setEdgeDirection(node1, node2, node3)
                end).to.throw()
            end)

            it("should error if the edge does not exist", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                expect(function()
                    graph:setEdgeDirection(node1, node2, node1)
                end).to.throw()
            end)

            it("should error if attempting to access an edge to the same node", function()
                local graph = DirectedGraph.new()
                local nodeId = graph:addNode(1)
                expect(function()
                    graph:setEdgeDirection(nodeId, nodeId, nodeId)
                end).to.throw()
            end)

            it("should permit changing the direction of an existing edge", function()
                local graph = DirectedGraph.new()
                local node1 = graph:addNode(1)
                local node2 = graph:addNode(2)
                graph:addEdge(node1, node2)
                expect(graph:getEdgeDirection(node1, node2)).to.equal(node2)
                graph:setEdgeDirection(node1, node2, node1)
                expect(graph:getEdgeDirection(node1, node2)).to.equal(node1)
            end)
        
        end)

    end)
end