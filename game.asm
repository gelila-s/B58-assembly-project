#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Gelila Samuel, 1008466928, samuelg3, gelila.samuel@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################
.eqv BASE_ADDRESS 	0x10008000
.eqv top_row	  	0x10008100 	#code of first pixel in second row
.eqv num_pixels	  	0x1000
.eqv bottom_left_corner	0x1000BF00 
.eqv jump_amount	1024
.eqv red		0xff0000
.eqv black		0x000000

.data
position:	.word 	0
enemies:	.word	0:7


.text
#t0, t1 - temp variables, #t2 - character position
.globl main
main:
	#clear screen
	li $t5, BASE_ADDRESS #start from top left corner
	li $t6, num_pixels
clear:	li $t0, black
	sw $t0, 0($t5)
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bnez $t6, clear
	
	#store initial position in memory
	li $t5, bottom_left_corner	
	sw $t5, position
	#initial state
	li $t0, red
	li $a0, 0
	jal redraw_character
	
	
	
	
main_loop:
	#Check for keyboard input.
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
	
	#Figure out if the player character is standing on a platform.
	#Update player location, enemies, platforms, power ups, etc.
	blt $t5, bottom_left_corner, gravity	#if player isnt on a platform, gravity to bottom row
	#Check for various collisions (e.g., between player and enemies).
	#Update other game state and end of game.
	#Erase objects from the old position on the screen.
	#Redraw objects in the new position on the screen.
	j main_loop
	
redraw_character: #redraw(old pos, offset) erases the charater at old_pos and redraws at old_pos + offset
	          #position is the location of the bottom-most, left-most framebuffer unit of the character
	          #arguments provided using stack? a0-a3? position could be stored in memory after each move
	          
	        li $t0, black		#load background colour
	        sw $t0, ($t5)		#delete old pos
		sw $t0, 4($t5)
		sw $t0, 8($t5)
		sw $t0, -256($t5)
		sw $t0, -512($t5)
		sw $t0, -768($t5)
		
		add, $t5, $t5, $a0	#move character
		
	        li $t0, red		#load character colour
	        sw $t0, 0($t5) #red square is our character
		sw $t0, 4($t5)
		sw $t0, 8($t5)
		sw $t0, -256($t5)
		sw $t0, -512($t5)
		sw $t0, -768($t5)
		jr $ra
	
keypress_happened:
	lw $t4, 4($t9)
	beq $t4, 0x61, respond_to_a
	beq $t4, 0x64, respond_to_d
	beq $t4, 0x77, respond_to_w
	#beq $t4, 0x73, respond_to_s
	beq $t4, 0x6B, main 	 #respond_to_k
	j main_loop
	
	
respond_to_a: 
	#li $t0, black		#load background colour
	#sw $t0, ($t5)		#delete old pos
	#subi $t5, $t5, 4	#move
	#li $t0, red		#load character colour
	#sw $t0, ($t5)		#draw new pos
	li $a0, -4
	jal redraw_character
	j sleep
	
respond_to_d: 
	#li $t0, black		#load background colour
	#sw $t0, ($t5)		#delete old pos
	#addi $t5, $t5, 4	#move
	#li $t0, red		#load character colour
	#sw $t0, ($t5)		#draw new pos
	li $a0, 4
	jal redraw_character
	j sleep
	
respond_to_w: 
	#should only happen if the character is on a platform (or double jump)
	blt $t5, top_row, sleep #don't move past the top of the screen
	li $t1, jump_amount
jump:	#li $t0, black		#load background colour	
	#sw $t0, ($t5)		#delete old pos
	#subi $t5, $t5, 256	#move
	#li $t0, red		#load character colour
	#sw $t0, ($t5)		#draw new pos
	li $a0, -256
	jal redraw_character
	subi $t1, $t1, 256
	li $v0, 32		#sleep for a bit
	li $a0, 50
	syscall
	bnez $t1, jump
	j sleep
	
#respond_to_s: 
	#li $t0, black		#load background colour
	#sw $t0, ($t5)		#delete old pos
	#addi $t5, $t5, 256	#move
	#li $t0, red		#load character colour
	#sw $t0, ($t5)		#draw new pos
	#li $a0, 256
	#jal redraw_character
	#j sleep

	
gravity:#li $t0, black		#load background colour	
	#sw $t0, ($t5)		#delete old pos
	#addi $t5, $t5, 256	#move
	#li $t0, red		#load character colour
	#sw $t0, ($t5)		#draw new pos
	li $a0, 256
	jal redraw_character
	#addi $t1, $t1, 256
	li $v0, 32
	li $a0, 5
	syscall
	#bne $t1, jump_amount, gravity
	j sleep


sleep:	li $v0, 32
	li $a0, 50
	syscall
	j main_loop
	
end:	li $v0, 10 # terminate the program gracefully
	syscall














