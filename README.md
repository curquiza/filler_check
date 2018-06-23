# filler_check

## Launch the correction

```
sh correction.sh -b [your_binary_path] [ -r ]
```
Default behaviour : you are the player 1 <br>
`-r` : you are the player 2

## Check your Filler's performance

```
sh filler_check.sh -1 [player] -2 [player] -m [map] [ -g [games_nb] -a ]
```
Default behaviour : 5 games are played, in the configuration (player 1 and player 2) you asked for.<br>
`-a` : you play as player 1 AND player 2.<br>
`-g [games_nb]` : number of games to play. Better to use with 100 or 1000 games to challenge your Filler.

### Example
