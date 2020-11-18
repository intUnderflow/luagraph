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

-- A DirectedGraph builds on the UndirectedGraph structure.
-- To store a direction, we add a new field to edges called `direction` which is the node ID of the node that the edge is directed towards.

local SERIALIZATION_VERSION = 1
local SERIALIZATION_TYPE = "lucy.sh/luagraph/DirectedGraph"

local HttpService = game:GetService("HttpService")
local UndirectedGraph = require(script.Parent.UndirectedGraph)

local DirectedGraph = setmetatable({}, UndirectedGraph)
DirectedGraph.__index = DirectedGraph

-- Creates a new directed graph and returns it.
-- overrides UndirectedGraph.new
function DirectedGraph.new()
    local self = setmetatable({}, DirectedGraph)
    -- All node values are stored as [node id] = value
    -- We allocate each node a number from 1 upwards using a counter.
    self.counter = 1
    self.nodes = {}

    return self
end

-- overrides UndirectedGraph._fromV1SerializedStructure in case behaviour inside UndirectedGraph changes in a breaking way in the future
function DirectedGraph._fromV1SerializedStructure(structure)
    local self = setmetatable({}, DirectedGraph)
    self.counter = structure.value.counter
    self.nodes = structure.value.nodes
    return self
end

-- overrides UndirectedGraph.deserialize
function DirectedGraph.deserialize(serialized)
    local serializedStructure = HttpService:JSONDecode(serialized)
    if serializedStructure.type ~= SERIALIZATION_TYPE then
        return error("This is not a serialized DirectedGraph")
    end
    if serializedStructure.version == 1 then
        return DirectedGraph._fromV1SerializedStructure(serializedStructure)
    else
        return error("This serialized structure is from a newer version of "
        .. "DirectedGraph and cannot be deserialized in this older version.")
    end
end

-- Adds an edge between two nodes to the graph with the given edgeValue.
-- Errors if the nodes already have an edge.
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
-- edgeValue: The value to assign to the created edge
-- The edge direction will be from nodeIDFrom towards nodeIDTo
-- overrides UndirectedGraph:addEdge
function DirectedGraph:addEdge(nodeIDFrom, nodeIDTo, edgeValue)
    assert(not self:hasEdge(nodeIDFrom, nodeIDTo), "The nodes already have an edge")
    table.insert(self:_getNode(nodeIDFrom).edges, {to = nodeIDTo, value = edgeValue, direction = nodeIDTo})
    table.insert(self:_getNode(nodeIDTo).edges, {to = nodeIDFrom, value = edgeValuem, direction = nodeIDTo})
end

-- Returns the direction that an edge points between the two nodes
-- nodeID1: The ID of one of the nodes
-- nodeID2: The ID of the other node
-- nodeID1 and nodeID2 need not be supplied in the order of direction, this is only necessary when creating a node.
function DirectedGraph:getEdgeDirection(nodeID1, nodeID2)
    assert(nodeID1 ~= nodeID2, "You must supply two different nodes")
    assert(self:hasEdge(nodeID1, nodeID2), "The nodes do not have an edge.")
    local _, edge = self:_getEdge(nodeID1, nodeID2)
    return edge.direction
end

-- Sets the direction of an edge after it has been initialized
-- nodeID1: The ID of one of the nodes
-- nodeID2: The ID of the other node
-- direction: The direction that the edge should point TOWARDS, this MUST be one of the nodes the edge is connected to.
-- nodeID1 and nodeID2 need not be supplied in the order of direction, this is only necessary when creating a node.
function DirectedGraph:setEdgeDirection(nodeID1, nodeID2, direction)
    assert(nodeID1 ~= nodeID2, "You must supply two different nodes")
    assert(self:hasEdge(nodeID1, nodeID2), "The nodes do not have an edge to edit")
    assert(direction == nodeID1 or direction == nodeID2, "direction MUST be the ID of one of the nodes the edge is connected to")

    local _, edge1 = self:_getEdge(nodeID1, nodeID2)
    edge1.direction = direction
    
    local _, edge2 = self:_getEdge(nodeID2, nodeID1)
    edge2.direction = direction
end

-- Serializes a DirectedGraph. Returns a string that can be passed to DirectedGraph.deserialize to
-- recover the original graph. This serialized structure is not intended for modification.
-- overrides UndirectedGraph.serialize
function DirectedGraph:serialize()
    local serializedStructure = {
        version = SERIALIZATION_VERSION,
        type = SERIALIZATION_TYPE,
        value = {
            nodes = self.nodes,
            counter = self.counter
        }
    }
    return HttpService:JSONEncode(serializedStructure)
end

return DirectedGraph