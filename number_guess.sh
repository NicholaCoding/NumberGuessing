#!/bin/bash

# Set PSQL variable
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$((RANDOM % 1000 + 1))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Validate username length
if [[ ${#USERNAME} -gt 22 ]]; then
  echo "Username cannot exceed 22 characters. Please try again."
  exit 1
fi

# Check if username exists in the database
USER_INFO=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 1000)")
else
  # Returning user
  echo "$USER_INFO" | while IFS='|' read RETURNED_USERNAME GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $RETURNED_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
GUESSES=0
while true; do
  read GUESS
  # Check if input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # Increment guess count
  ((GUESSES++))

  # Compare guess with the secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update the database
if [[ -z $USER_INFO ]]; then
  # New user, set first game stats
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$GUESSES WHERE username='$USERNAME'")
else
  echo "$USER_INFO" | while IFS='|' read RETURNED_USERNAME GAMES_PLAYED BEST_GAME
  do
    NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
    if [[ $GUESSES -lt $BEST_GAME ]]; then
      NEW_BEST_GAME=$GUESSES
    else
      NEW_BEST_GAME=$BEST_GAME
    fi
    UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NEW_BEST_GAME WHERE username='$USERNAME'")
  done
fi
