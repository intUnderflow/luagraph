local HttpService = game:GetService("HttpService")
local TestEZ = require(script.Parent.Parent.Parent.TestEZ)

local UndirectedGraph = require(script.Parent)

local NAUGHTY_STRINGS = HttpService:JSONDecode(
    HttpService:GetAsync(
        "https://raw.githubusercontent.com/minimaxir/big-list-of-naughty-strings/master/blns.json"
    )
)
local TYPES = {
    nil = {
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
    function = {
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
        game:GetService("CoreGui") -- RobloxLocked instance
    }
}

return function()
    describe("UndirectedGraph", function()

        describe(".new", function()
            it("should return an undirected graph when .new() is called", function()
                expect(UndirectedGraph.new()).to.not.equal(nil)
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

                for key, value in ipairs(typeList) do
                
                    it(("should create nodes with %s values (%d/%d)"):format(typeName, key, #typeList), function()
                        local graph = UndirectedGraph.new()
                        local nodeId = graph:addNode(value)
                        expect(graph:getNodeValue(nodeId)).to.equal(value)
                    end)

                end

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

            end)
            
            it("should mutate the value of a node", function()

            end)

        end)

    end)
end