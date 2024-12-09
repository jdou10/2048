# 2048 Clone Using Haskell
The game will probably operate in a terminal interface with a text-based grid and input controls, allowing players to interact with the game through keyboard commands. We will use GitHub repository to keep track. 
We are a two-person team, and we will split the tasks as follows: 
1. One team member will focus on implementing the game logic in Haskell, including grid initialization, tile movement, merging mechanics, and score tracking. This logic will serve as the foundation for both the terminal version and future graphical versions. 
2. The other team member will implement the terminal-based user interface, including display updates for the grid and player prompts for difficulty selection. This member will also handle player input handling to facilitate gameplay.

## Project Description
- to run the game use stack to build and stack to run
- then it will give you terminal prompt for difficulty choose accordingly 

## Things need to be done:
- Set up the environment using Stack (most likely).
- Create some basic project files and establish a directory structure to separate game logic and interface. 
- Implement a terminal prompt for difficulty selection, allowing players to choose from various game difficulty levels. 
- Develop functions for grid initialization and random tile spawning, with difficulty-based variations.
- Implement movement functions for sliding and merging tiles according to the 2048 rules. 
- Set up scoring to track the player’s progress. 
- Implement a text-based grid display that updates after each move, showing tile values and scores. 
- Design an input system for player actions. In particular, using arrows.
- Add visual enhancements within the terminal (like colors for different tile values) to improve readability.

## Bug need to be fixed:
- Number merging error
- Helper function randomElem
- MoveAndAddRandom main funtion
- mergeRow (*try not to let it bounce around the board*)
- updateTile & moveLeft (less important)
