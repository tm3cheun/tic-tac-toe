#!/usr/bin/env ruby
class Board
  attr_accessor :board
  attr_accessor :size
  attr_accessor :winning_symbol

  def initialize(size)
    @size = size
    @board = Array.new(size*size, "-")
    @winning_symbol = "-"
  end
  
  def check(index_num, s)
    s.write "\nOccupied!" if (@board[index_num] != "-")
    @board[index_num] != "-"
  end
  
  def set(index_num, player)
    @board[index_num] = player
  end
  
  def invalid(s, index_number)
    s.write "\nInvalid spot" if (index_number < 0 or index_number >= @size*@size)
  end

  def print_board(s)
    @board.each_index do |x|
      s.write @board[x]
      s.write "\n" if x % @size == (@size-1)
    end
  end
  
  def print_template(s)
    s.write "\n\nTemplate\n"
    @board.each_index do |x|
      s.write x
      if @size > 3
        s.write " " if x < 10
        s.write " "
      end
      if (x%@size) == (size-1)
        s.write "\n"
      end
    end
    s.write "\n"
  end
  
  def check_end
    @board.each do |item|
      return false if (item == "-")
    end
    return true
  end

  # for /
  def diagonal_win_1?
    count = 0
    temp = @board[@size-1]
    for i in 1..@size
      count += 1 if (@board[i*(@size-1)] != "-" and @board[i*(@size-1)] == temp)
    end

    if count == @size
      @winning_symbol = temp
      return true
    end
    return false
  end

  # for \
  def diagonal_win_2?
    count = 0
    temp = @board[@size+1]
    for i in 0..(@size-1)
      count += 1 if (@board[i*(@size+1)] != "-" and @board[i*(@size+1)] == temp)
    end

    if count == @size
      @winning_symbol =temp
      return true
    end
    return false
  end
  
  def horizontal_win?
    for i in 0..@size-1
      count = 0
      temp = @board[i*@size]
      for j in 0..@size-1
        count += 1 if (@board[(i*@size)+j] != "-" and @board[(i*@size)+j] == temp)
      end

      if count == @size
        @winning_symbol = temp
        return true
      end
    end
    return false
  end
  
  def vertical_win?
    for i in 0..@size-1
      count = 0
      temp = @board[i]
      for j in 0..@size-1
        count += 1 if @board[i+(size*j)] != "-" and @board[i+(size*j)] == temp
      end
      if count == @size
        @winning_symbol = temp
        return true
      end
    end
    return false
  end
  
  def game_won?
    return diagonal_win_1? or diagonal_win_2? or horizontal_win? or vertical_win?
  end
end

def come_back_later s
  s.write "Busy. Try again later."
  s.close
end

class Player  
  attr_accessor :name, :player, :wins, :socket
  
  def initialize s, player
    @player = player
    @socket = s
  end

  def welcome_and_wait_for_two_players
    @socket.write "\nWelcome Player #{@player}\n"

    while $number_of_players < 2 do
      socket.write "\nWaiting for another player"
      sleep 1
    end
    socket.write "\nReady to play!\n"
  end

  def get_move
    begin
      socket.write "\nYour move: "
      a = @socket.gets.to_i
      $board.invalid(@socket, a) 
    end while a < 0 or a >= 9 or $board.check(a, @socket) == true

    $board.set(a, $symbol)
    $turn_number += 1
    if $symbol == "o"
      $symbol = "x"
    else
      $symbol = "o"
    end
  end

  def my_turn?
    ( ($turn_number - player ) % 2 == 0 )
  end
  
  def game_in_progress?
    return ($board.game_won? == false and $board.check_end == false)
  end
  
  def print_board
    $board.print_template(socket)
    $board.print_board(socket)
  end
  
  def print_winner
    if $board.winning_symbol == "x"   
      socket.write "\nPlayer 1 wins!"
    elsif $board.winning_symbol == "o" 
      socket.write "\nPlayer 2 wins!"  
    else
      socket.write "\nNo one wins!"
    end 
  end

  def play
    welcome_and_wait_for_two_players
    while game_in_progress?
      if my_turn?
        print_board
        get_move
        print_board if game_in_progress?
      else
        socket.write "Waiting...\n"
      end
      sleep 1
    end
    
    $board.print_board(socket)
    print_winner
    socket.write "\nBye!\n"
    $number_of_players = 0
  end
end

require "socket"
socket = TCPServer.new('0.0.0.0', 10240)
$number_of_players = 0

loop do
  Thread.start(socket.accept) do |s|
    $number_of_players += 1
    $turn_number = 1
    $symbol = "x"
    $board = Board.new(3)
    
    if $number_of_players > 2
      come_back_later s
    end
    
    player = Player.new s, $number_of_players
    player.play
    
    s.close
  end
end
