class ChessBoard
	attr_accessor :board
	
	def initialize board
		@board=board
	end
	
	def populate_possition chess_piece, possition_x, possition_y
		@board[possition_x][possition_y]=chess_piece
	end
	
	def get_piece_in_possition? possition
		@board[possition[0]][possition[1]]
	end
	
	def possition_empty? possition
		@board[possition[0]][possition[1]]==nil
	end

	def correct_vertical_direction? piece, origin, destination
		(piece[0] == "w" && (destination[1] <= origin[1])) || (piece[0] == "b" && (destination[1] >= origin[1]))
	end
	
	def eat? possition, piece
		(@board[possition[0]][possition[1]][0]) != piece[0]
	end

	def contains_piece_of_color color, possition
		(@board[possition[0]][possition[1]])[0] == color
	end

	def remove_piece possition
		@board[possition[0]][possition[1]] = nil
	end

	def possition_in_board? possition
		(possition[0].between?(0, 7)) && (possition[1].between?(0, 7))
	end

	def is_horizontal_path_free? orig, dest
		orig[1]>dest[1] ? !(@board[orig[0]][(dest[1]+1)..(orig[1]-1)].any?) : !(@board[orig[0]][(orig[1]+1)..(dest[1]-1)].any?)
	end

	def is_vertical_path_free? orig, dest
		path = @board.map {|row| row[orig[1]]}
		orig[0]>dest[0] ? !(path[(dest[0]+1)..(orig[0]-1)].any?) : !(path[(orig[0]+1)..(dest[0]-1)].any?)
	end

	def get_diagonal sub_board
		(0..(sub_board.size - 1)).collect{|i| sub_board[i][i]}
	end

	def is_diagonal_path_free? origin, destination
		if origin[0]>destination[0] && origin[1]>destination[1]
			sub_board = @board[(destination[0]+1)..(origin[0]-1)].map { |array| array[(destination[1]+1)..(origin[1]-1)] }
			diagonal = get_diagonal sub_board
		elsif origin[0]<destination[0] && origin[1]>destination[1]
			sub_board = @board[(origin[0]+1)..(destination[0]-1)].map { |array| array[(destination[1]+1)..(origin[1]-1)] }
			diagonal = get_diagonal sub_board
		elsif origin[0]>destination[0] && origin[1]<destination[1]
			sub_board = @board[(destination[0]+1)..(origin[0]-1)].map { |array| array[(origin[1]+1)..(destination[1]-1)] }
			diagonal = get_diagonal sub_board.reverse
		elsif origin[0]<destination[0] && origin[1]<destination[1]
			sub_board = @board[(origin[0]+1)..(destination[0]-1)].map { |array| array[(origin[1]+1)..(destination[1]-1)] }
			diagonal = get_diagonal sub_board.reverse
		end		
		!diagonal.any?
	end

	def change_piece_possition orig, dest
		populate_possition (get_piece_in_possition? orig), dest[0], dest[1]
	end
	
	def print_board
		@board.each do |horiz_array|
			print "|"
			horiz_array.each do |possition|
				print (possition == nil ? "  |" : "#{possition}|")
			end
			print "\n-------------------------\n"
		end
	end
end

class ChessValidator
	attr_accessor :mode
	def start_chess_validator
		board_arrays = Array.new(8){Array.new(8, nil)}
		@chessboard = ChessBoard.new board_arrays
		
		if @mode == "simple"
			#load by file reader --> simple board
			load_initial_board "simple_board.txt"
			# Print board
			@chessboard.print_board
			#create file for results --> simple results
			f1 = create_file_write "simple_results.txt"
			#load file with moves --> simple moves
			load_testing_moves "simple_moves.txt", f1
		elsif @mode == "complex"
			#load by file reader --> complex board
			load_initial_board "complex_board.txt"
			# Print board
			@chessboard.print_board
			#create file for results --> complex results
			f1 = create_file_write "complex_results.txt"
			#load file with moves --> complex moves
			load_testing_moves "complex_moves.txt", f1
		elsif @mode == "play"
			#load by file reader --> simple board
			load_initial_board "simple_board.txt"
			# Print board
			@chessboard.print_board
			@turn = "white"
			game
		end
	end

	def game
		@play = true
		while @play
			@correct_move = false
			while !@correct_move
				puts "The turn is on #{@turn}s, please take your action (orig & dest - i.e. a2 a4):"
				action = gets.chomp
				instr = action.split
				if !correct_instruction? instr
					incorrect_move
				else
					orig = parse_coordenates instr[0]
					dest = parse_coordenates instr[1]
					if !(@chessboard.possition_empty? orig)
						if @chessboard.contains_piece_of_color @turn[0], orig
							if validate_move orig, dest
								@turn = move_piece_possition orig, dest
							else
								incorrect_move
							end
						else
							incorrect_move
						end
					else
						incorrect_move
					end
				end
			end
		end
	end

	def correct_instruction? instr
		if instr.length == 2 
			if instr[0].length == 2 || instr[1].length == 2
				true
			else
				false
			end
		else
			false
		end
	end

	def move_piece_possition orig, dest
		puts "Correct move!\n"
		@correct_move = true
		@chessboard.change_piece_possition orig, dest
		@chessboard.remove_piece orig
		@chessboard.print_board
		@turn == "white" ? "black" : "white"
	end

	def incorrect_move
		puts "The move you are trying is incorrect, please try again."
		@correct_move = false
	end
	
	def check_piece_and_move_validation piece_reference, origin, destination
		if piece_reference[1] == "R"
			Rook.valid_move? origin, destination, @chessboard
		elsif piece_reference[1] == "Q"
			Queen.valid_move? origin, destination, @chessboard
		elsif piece_reference[1] == "K"
			King.valid_move? origin, destination, @chessboard
		elsif piece_reference[1] == "P"
			(Pawn.valid_move? origin, destination, @chessboard) && (@chessboard.correct_vertical_direction? piece_reference, origin, destination)
		elsif piece_reference[1] == "N"
			Knight.valid_move? origin, destination
		elsif piece_reference[1] == "B"
			Bishop.valid_move? origin, destination, @chessboard
		end
	end

	def validate_move origin, destination, f_results=nil
		piece_reference = @chessboard.get_piece_in_possition? origin
		if piece_reference && (@chessboard.possition_in_board? destination)
			if (@chessboard.possition_empty? destination) || (@chessboard.eat? destination, piece_reference)
				valid_move = check_piece_and_move_validation piece_reference, origin, destination
				if valid_move
					if @mode == "simple" || @mode == "complex"
						write_file_results f_results, "LEGAL"
					elsif @mode == "play"
						true
					end
				else
					if @mode == "simple" || @mode == "complex"
						write_file_results f_results, "ILLEGAL"
					elsif @mode == "play"
						false
					end
				end	
			else
				write_file_results f_results, "ILLEGAL"
			end
		else
			write_file_results f_results, "ILLEGAL"
		end
	end
	
	def load_initial_board file
		f = File.open(file, "r")
		i = j = 0
		f.each_line do |line|
  			line.split.each do |piece|
  				if piece != "--"
  					@chessboard.populate_possition piece, j, i
  				end
  				i+=1
  			end
  			i=0
  			j+=1
		end
		f.close
	end

	def parse_coordenates pos
		[(pos[1].to_i-8).abs, ((pos[0].ord)-97).to_i]
	end

	def load_testing_moves file, f_results
		f = File.open(file, "r")
		f.each_line do |line|
	  		instr = line.split
	  		validate_move (parse_coordenates instr[0]), (parse_coordenates instr[1]), f_results
		end
		f.close
	end

	def create_file_write file
		f = File.open(file, "w")
	end

	def write_file_results f, result
		f.puts result
	end
end

class Queen
	def self.valid_move? origin, destination, chessboard
		if is_horizontal_move? origin, destination
			chessboard.is_horizontal_path_free? origin, destination
		elsif is_vertical_move? origin, destination
			chessboard.is_vertical_path_free? origin, destination	
		elsif is_diagonal_move? origin, destination
			chessboard.is_diagonal_path_free? origin, destination
		else
			false		
		end
	end
	def self.is_horizontal_move? origin, destination
		origin[0]==destination[0]
	end
	def self.is_vertical_move? origin, destination
		origin[1]==destination[1]
	end
	def self.is_diagonal_move? origin, destination
		((origin[1]-destination[1])/(origin[0]-destination[0])).abs == 1
	end
end

class King
	def self.valid_move? origin, destination, chessboard
		if (is_horizontal_move? origin, destination) && (correct_distance? origin[1], destination[1]) 
			chessboard.is_horizontal_path_free? origin, destination
		elsif (is_vertical_move? origin, destination) && (correct_distance? origin[0], destination[0]) 
			chessboard.is_vertical_path_free? origin, destination	
		elsif (is_diagonal_move? origin, destination) && (correct_distance? origin[0], destination[0])
			chessboard.is_diagonal_path_free? origin, destination
		else
			false		
		end
	end
	def self.is_horizontal_move? origin, destination
		# print origin[0]
		# print "\n destin"
		# print destination[0]
		origin[0]==destination[0]
	end
	def self.is_vertical_move? origin, destination
		origin[1]==destination[1]
	end
	def self.is_diagonal_move? origin, destination
		((origin[1]-destination[1])/(origin[0]-destination[0])).abs == 1
	end
	def self.correct_distance? origin, destination
		(origin-destination).abs == 1
	end
end

class Bishop
	def self.valid_move? origin, destination, chessboard
		(is_diagonal_move? origin, destination) ? (chessboard.is_diagonal_path_free? origin, destination) : false
	end

	def self.is_diagonal_move? origin, destination
		((origin[1]-destination[1])/(origin[0]-destination[0])).abs == 1
	end
end

class Rook
	def self.valid_move? origin, destination, chessboard
		if (destination[0] == origin[0] || destination[1] == origin[1])
			if is_horizontal_move? origin, destination
				chessboard.is_horizontal_path_free? origin, destination
			elsif is_vertical_move? origin, destination
				chessboard.is_vertical_path_free? origin, destination
			else
				false
			end
		end
	end

	def self.is_horizontal_move? origin, destination
		origin[0]==destination[0]
	end

	def self.is_vertical_move? origin, destination
		origin[1]==destination[1]
	end
end

class Pawn
	def self.valid_move? origin, destination, chessboard
		
		if (is_vertical_move? origin, destination) && (correct_number_of_possitions_in_move? origin, destination) 
			chessboard.is_vertical_path_free? origin, destination
		else
			false
		end
	end

	def self.correct_number_of_possitions_in_move? origin, destination
		(origin[0]-destination[0]).abs <= 2
	end

	def self.is_vertical_move? origin, destination
		origin[1]==destination[1]
	end
end

class Knight
	def self.valid_move? origin, destination
		if (destination == [origin[0]+2, origin[1]+1]) || (destination == [origin[0]+2, origin[1]-1])
			true
		elsif (destination == [origin[0]-2, origin[1]+1]) || (destination == [origin[0]-2, origin[1]-1])
			true
		elsif (destination == [origin[0]+1, origin[1]+2]) || (destination == [origin[0]-1, origin[1]+2])
			true
		elsif (destination == [origin[0]+1, origin[1]-2]) || (destination == [origin[0]-1, origin[1]-2])
			true
		else
			false
		end
	end
end

chess_validator_1 = ChessValidator.new
puts "Game mode (simple, complex or play)?"
chess_validator_1.mode = gets.chomp
chess_validator_1.start_chess_validator