-- A representation of an Undirected graph.
local SERIALIZATION_VERSION = 1
local SERIALIZATION_TYPE = "lucy.sh/luagraph/UndirectedGraph"

local HttpService = game:GetService("HttpService")

local function findEdgeInNode(node, nodeToFindConnectionTo)
    for index, edge in ipairs(node.edges) do
        if edge.to == nodeToFindConnectionTo then
            return index, edge
        end
    end
    return nil
end

local function copyTable(tableToCopy)
    -- This runs C-side so im hoping its faster than anything recursive we could do in pure Lua
    return HttpService:JSONDecode(HttpService:JSONEncode(tableToCopy))
end

local UndirectedGraph = {}
UndirectedGraph.__index = UndirectedGraph

-- Creates a new undirected graph and returns it.
function UndirectedGraph.new()
    local self = setmetatable({}, UndirectedGraph)
    -- All node values are stored as [node id] = value
    -- We allocate each node a number from 1 upwards using a counter.
    self.counter = 1
    self.nodes = {}

    return self
end

function UndirectedGraph._fromV1SerializedStructure(structure)
    local self = setmetatable({}, UndirectedGraph)
    self.counter = structure.value.counter
    self.nodes = structure.value.nodes
    return self
end

function UndirectedGraph.deserialize(serialized)
    local serializedStructure = HttpService:JSONDecode(serialized)
    if serializedStructure.type ~= SERIALIZATION_TYPE then
        return error("This is not a serialized UndirectedGraph")
    end
    if serializedStructure.version == 1 then
        return UndirectedGraph._fromV1SerializedStructure(serializedStructure)
    else
        return error("This serialized structure is from a newer version of "
        .. "UndirectedGraph and cannot be deserialized in this older version.")
    end
end

function UndirectedGraph:_getNode(nodeID)
    return self.nodes[nodeID]
end

function UndirectedGraph:_setNode(nodeID, value)
    self.nodes[nodeID] = value
end

function UndirectedGraph:_getEdge(nodeIDFrom, nodeIDTo)
    return findEdgeInNode(self:_getNode(nodeIDFrom), nodeIDTo)
end

-- Returns true if a node with a given nodeID exists in the graph, false otherwise.
function UndirectedGraph:hasNode(nodeID)
    return self:_getNode(nodeID) ~= nil
end

-- Adds a node to the graph
-- nodeValue: The value for the node.
function UndirectedGraph:addNode(nodeValue)
    local nodeID = self.counter
    self.counter = self.counter + 1
    self:_setNode(nodeID, {
        value = nodeValue,
        edges = {}
    })
    return nodeID
end

-- Gets the value of a node
-- nodeID: The ID of the node returned from :addNode
function UndirectedGraph:getNodeValue(nodeID)
    assert(self:hasNode(nodeID), "The node does not exist.")
    return self:_getNode(nodeID).value
end

-- Gets the nodes directly connected to this node from its edges
-- nodeID: The ID of the node returned from :addNode
function UndirectedGraph:getNodeEdges(nodeID)
    assert(self:hasNode(nodeID), "The node does not exist.")
    return copyTable(self:_getNode(nodeID).edges)
end

-- Edits a node in the graph to change its current value.
-- nodeID: The ID of the node returned from :addNode
-- newValue: The new value for the node.
function UndirectedGraph:setNodeValue(nodeID, newValue)
    assert(self:hasNode(nodeID), "The node does not exist.")
    self:_getNode(nodeID).value = newValue
end

-- Removes a node from the graph and breaks all of its edges with other nodes.
-- nodeID: The ID of the node returned from :addNode
function UndirectedGraph:removeNode(nodeID)
    assert(self:hasNode(nodeID), "The node does not exist.")
    local node = self:_getNode(nodeID)
    for _, edge in ipairs(node.edges) do
        self:removeEdge(nodeID, edge.to)
    end
    self:_setNode(nodeID, nil)
end

-- Returns true if two nodes on the graph are connected by an edge and false otherwise.
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
function UndirectedGraph:hasEdge(nodeIDFrom, nodeIDTo)
    assert(self:hasNode(nodeIDFrom), "The from node does not exist.")
    assert(self:hasNode(nodeIDTo), "The to node does not exist.")
    assert(nodeIDFrom ~= nodeIDTo, "The from node and to node are the same node.")
    return self:_getEdge(nodeIDFrom, nodeIDTo) ~= nil
end

-- Adds an edge between two nodes to the graph with the given edgeValue.
-- Errors if the nodes already have an edge.
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
-- edgeValue: The value to assign to the created edge
function UndirectedGraph:addEdge(nodeIDFrom, nodeIDTo, edgeValue)
    assert(not self:hasEdge(nodeIDFrom, nodeIDTo), "The nodes already have an edge")
    table.insert(self:_getNode(nodeIDFrom).edges, {to = nodeIDTo, value = edgeValue})
    table.insert(self:_getNode(nodeIDTo).edges, {to = nodeIDFrom, value = edgeValue})
end

-- Removes the edge between two nodes on the graph.
-- Errors if the nodes do not have an edge.
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
function UndirectedGraph:removeEdge(nodeIDFrom, nodeIDTo)
    assert(self:hasEdge(nodeIDFrom, nodeIDTo), "The nodes do not have an edge to remove")
    
    local indexOfEdgeOnNodeFrom = self:_getEdge(nodeIDFrom, nodeIDTo)
    table.remove(self:_getNode(nodeIDFrom).edges, indexOfEdgeOnNodeFrom)

    local indexOfEdgeOnNodeTo = self:_getEdge(nodeIDTo, nodeIDFrom)
    table.remove(self:_getNode(nodeIDTo).edges, indexOfEdgeOnNodeTo)
end

-- Returns the value of an edge between two nodes
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
function UndirectedGraph:getEdgeValue(nodeIDFrom, nodeIDTo)
    assert(self:hasEdge(nodeIDFrom, nodeIDTo), "The nodes do not have an edge.")
    local _, edge = self:_getEdge(nodeIDFrom, nodeIDTo)
    return edge.value
end

-- Edits an edge between two nodes to change the edgeValue.
-- Errors if the edge between the two nodes does not exist.
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
-- newEdgeValue: The new value to assign to the edge between the nodes
function UndirectedGraph:editEdge(nodeIDFrom, nodeIDTo, newEdgeValue)
    assert(self:hasEdge(nodeIDFrom, nodeIDTo), "The nodes do not have an edge to edit")

    local _, edge1 = self:_getEdge(nodeIDFrom, nodeIDTo)
    edge1.value = newEdgeValue

    local _, edge2 = self:_getEdge(nodeIDTo, nodeIDFrom)
    edge2.value = newEdgeValue
end

-- Either adds an edge between two nodes with a given value or edits an existing edge between the two nodes
-- to hold a specific value.
-- nodeIDFrom: The ID of one of the nodes
-- nodeIDTo: The ID of the other node
-- edgeValue: The value to assign to the edge
function UndirectedGraph:addOrEditEdge(nodeIDFrom, nodeIDTo, edgeValue)
    if self:hasEdge(nodeIDFrom, nodeIDTo) then
        self:editEdge(nodeIDFrom, nodeIDTo, edgeValue)
    else
        self:addEdge(nodeIDFrom, nodeIDTo, edgeValue)
    end
end

-- Serialized an UndirectedGraph. Returns a string that can be passed to UndirectedGraph.deserialize to
-- recover the original graph. This serialized structure is not intended for modification.
function UndirectedGraph:serialize()
    -- TODO: In the future we should look at structures that use less data by not storing as much
    -- structural information such as keys.
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

return UndirectedGraph