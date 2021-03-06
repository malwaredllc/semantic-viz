module Graph where
import Data.Maybe
import Data.Map (Map)
import Data.List.Unique
import qualified Data.Map as M
import Data.Graph
import Data.Graph.Inductive
import Debug.Trace

-- Project modules
import Utils (push, pop)

-- debug = flip traceShow

-- Recursive(-ish) function for building the adjacency list. Uses number of leading spaces of each line of
-- output from Wordnet to determine node placement in graph.
-- NOTE: I say recursive-ish because the helper functions it calls all call this function again after
--       completing their respective operations (i.e. tail recursion)
buildAdjacencyList :: [(String, Int)] -> [String] -> Int -> Map String [String] -> Map String [String]
buildAdjacencyList [] _ _ hashmap = hashmap
buildAdjacencyList ((word, spaces) : tail_pairs) parents currNumSpaces hashmap
    | spaces > currNumSpaces = addNeighborNewParent tail_pairs parents currNumSpaces word spaces hashmap
    | spaces < currNumSpaces = addNeighborOldParent tail_pairs parents currNumSpaces word spaces hashmap
    | otherwise              = addNeighborSameParent tail_pairs parents currNumSpaces word spaces hashmap

-- Add neighbor to current node without updating current parent node pointer
addNeighborSameParent :: [(String, Int)] -> [String] -> Int -> String -> Int -> Map String [String] -> Map String [String]
addNeighborSameParent pairs parents currNumSpaces word spaces hashmap = do
    let (_, oldParents) = pop parents -- pop last item on parent hiearchy (if spaces didn't change, it has no children)
        currParent = head oldParents -- `debug` oldParents

        -- add parent -> node relationship
        vals = M.lookup currParent hashmap
        newVals = uniq (word: (fromMaybe [] vals))
        updatedHashmap = M.insert currParent newVals hashmap

        -- add node -> parent relationship
        vals2 = M.lookup word updatedHashmap
        newVals2 = uniq (currParent: (fromMaybe [] vals2))
        updatedHashmap2 = M.insert word newVals2 updatedHashmap

        -- add word to parents in case next line has more spaces and it becomes a parent
        (__, newParents) = push word oldParents
    buildAdjacencyList pairs newParents currNumSpaces updatedHashmap2


-- Update current node to new word and add neighbor
addNeighborNewParent :: [(String, Int)] -> [String] -> Int -> String -> Int -> Map String [String] -> Map String [String]
addNeighborNewParent pairs parents currNumSpaces word spaces hashmap = do
    let currParent = head parents
        (_, newParents) = push word parents
        currNumSpaces = spaces -- `debug` parents

        -- add node -> parent relationship
        vals = M.lookup word hashmap
        newVals = uniq (currParent: (fromMaybe [] vals))
        updatedHashmap = M.insert word newVals hashmap

        -- add parent -> node relationship
        vals2 = M.lookup currParent updatedHashmap
        newVals2 = uniq (word: (fromMaybe [] vals2))
        updatedHashmap2 = M.insert currParent newVals2 updatedHashmap
    buildAdjacencyList pairs newParents currNumSpaces updatedHashmap2


-- Update current node to old parent and add neighbor
addNeighborOldParent :: [(String, Int)] -> [String] -> Int -> String -> Int -> Map String [String] -> Map String [String]
addNeighborOldParent pairs parents currNumSpaces word spaces hashmap = do
    let (prevParent, tmpParents) = pop parents -- pop last parent from stack and use new top element as parent
        (_, newParents) = pop tmpParents
        currParent = head newParents -- `debug` newParents
        nextNumSpaces = spaces

        -- add parent -> node relationship
        vals = M.lookup currParent hashmap
        newVals = uniq (word: (fromMaybe [] vals))
        updatedHashmap = M.insert currParent newVals hashmap

        -- add node -> parent relationship
        vals2 = M.lookup word hashmap
        newVals2 = uniq (currParent: (fromMaybe [] vals2))
        updatedHashmap2 = M.insert word newVals2 updatedHashmap

        nextParents = case currNumSpaces of
            currNumSpaces
                | currNumSpaces == spaces   -> ("": newParents) -- prepend dummy str for addNeighborSameParent function to pop
                | otherwise                 -> (word: newParents)
    buildAdjacencyList pairs nextParents nextNumSpaces updatedHashmap2


-- Make unlabelled inductive graph from list of vertices + edges
makeUnlabelledGraph :: [Node] -> [Data.Graph.Edge] -> Gr () ()
makeUnlabelledGraph v e = do
    Data.Graph.Inductive.mkUGraph v e

-- Make labelled inductive graph from list of labelled vertices + edges
makeLabelledGraph :: [LNode a] -> [LEdge ()] -> Gr a ()
makeLabelledGraph v e = do
    Data.Graph.Inductive.mkGraph v e