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
.eqv BASE_ADDRESS 		0x10008000
.eqv top_row	  		0x10008100 	#code of first pixel in second row
.eqv num_pixels	  		0x1000
.eqv units			64
.eqv bottom_left_corner		0x1000BF00
.eqv bottom_right_corner	0x1000BE01
.eqv jump_amount		1280
.eqv floor			0x1000BC00
.eqv above_floor		0x1000BB00

#COLOURS		
.eqv black		0x000000
	#character
.eqv c_blue		0x3f51b5
.eqv c_purple		0x9c27b0
.eqv c_skin		0xc68642
	#enemies
.eqv e_body		0x009687
.eqv e_eye_dark		0xd1c4e9
.eqv e_eye_light	0xede7f6
	#setting
.eqv background		0x9e9e9e
.eqv platform_l		0x607d8b
.eqv platform_d		0x546e7a

.data
position:	.word 	0x1000BF00  
direction: 	.word 	0
enemies:	.word	0:7


.text
#t0, t1 - temp variables, #t2 - character position
.globl main
main:
	#clear screen
	li $t5, BASE_ADDRESS #start from top left corner
	li $t6, num_pixels
	li $t0, background
clear:	sw $t0, 0($t5)
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bnez $t6, clear
	
	jal draw_level
	
	#store initial position in memory
	li $t5, above_floor
	addi $t5, $t5, 20
	sw $t5, position
	#initial state
	li $t0, c_blue
	li $a0, 0
	jal redraw_character
	
main_loop:
	#Check for keyboard input.
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
	
	#Figure out if the player character is standing on a platform.
	#Update player location, enemies, platforms, power ups, etc.
	blt $t5, above_floor, gravity	#if player isnt on a platform, gravity to bottom row
	#Check for various collisions (e.g., between player and enemies).
	#Update other game state and end of game.
	#Erase objects from the old position on the screen.
	#Redraw objects in the new position on the screen.
	j main_loop
	
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
	
	li $t1, 1		#change direction
	sw $t1, direction
	li $a0, -4
	jal redraw_character
	j sleep
	
respond_to_d: 
	#li $t0, black		#load background colour
	#sw $t0, ($t5)		#delete old pos
	#addi $t5, $t5, 4	#move
	#li $t0, red		#load character colour
	#sw $t0, ($t5)		#draw new pos
	
	li $t1, 0		#change direction
	sw $t1, direction
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
	#li $v0, 32		#sleep for a bit
	#li $a0, 50
	#syscall
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
	#li $v0, 32
	#li $a0, 5
	#syscall
	#bne $t1, jump_amount, gravity
	j sleep


sleep:	li $v0, 32
	li $a0, 50
	syscall
	j main_loop
	
redraw_character: #redraw(old pos, offset) erases the charater at old_pos and redraws at old_pos + offset
	          #position is the location of the bottom-most, left-most framebuffer unit of the character
	          #arguments provided using stack? a0-a3? position could be stored in memory after each move
	          
	        #check direction and jump to left or to right 
	        
	        li $t0, background	#load background colour
	        #pants	
	        sw $t0, 0($t5)
	        sw $t0, -256($t5)
	        sw $t0, -252($t5)
	        sw $t0, -248($t5)
	        sw $t0, -244($t5)
	        sw $t0, 12($t5) 
	        
	        #shirt
	        sw $t0, -512($t5) 
	        sw $t0, -508($t5)
	        sw $t0, -504($t5)
	        sw $t0, -500($t5)
	        sw $t0, -768($t5) 
	        sw $t0, -764($t5)
	        sw $t0, -760($t5)
	        sw $t0, -756($t5)
	        sw $t0, -1024($t5) 
	        sw $t0, -1020($t5)
	        sw $t0, -1016($t5)
	        sw $t0, -1012($t5)
	        
	        
	        #arms
	        sw $t0, -516($t5) 	#left
	        sw $t0, -772($t5)	
	        sw $t0, -496($t5)	#right
	        sw $t0, -752($t5)
	        
	        #hair
	        sw $t0, -1028($t5)
	        sw $t0, -1032($t5)
	        sw $t0, -1036($t5)
	        sw $t0, -1284($t5)
	        sw $t0, -1288($t5)
	        sw $t0, -1292($t5)
	        sw $t0, -1540($t5)
	        sw $t0, -1544($t5)
	        sw $t0, -1796($t5)
	        sw $t0, -1800($t5)
	        sw $t0, -2052($t5)
	        sw $t0, -2308($t5)
	        sw $t0, -2304($t5)
	        sw $t0, -2560($t5)
	        sw $t0, -2556($t5)
	        sw $t0, -2552($t5)
	        sw $t0, -2548($t5)
	        sw $t0, -2544($t5)
	        sw $t0, -2288($t5)
	        sw $t0, -2284($t5)
	        sw $t0, -2028($t5)
	        sw $t0, -1772($t5)
	        sw $t0, -1516($t5)
	        sw $t0, -1260($t5)
	        sw $t0, -1004($t5)
	        sw $t0, -1008($t5)
	        
	        #face
	        sw $t0, -1788($t5)
	        sw $t0, -1780($t5)
	        sw $t0, -1784($t5)
	        sw $t0, -1792($t5)
	        sw $t0, -1776($t5)
	        sw $t0, -1280($t5)
	        sw $t0, -1276($t5)
	        sw $t0, -1272($t5)
	        sw $t0, -1268($t5)
	        sw $t0, -1264($t5)
	        sw $t0, -1536($t5)
	        sw $t0, -1532($t5)
	        sw $t0, -1528($t5)
	        sw $t0, -1524($t5)
	        sw $t0, -1520($t5)
	        sw $t0, -2048($t5)
	        sw $t0, -2044($t5)
	        sw $t0, -2040($t5)
	        sw $t0, -2036($t5)
	        sw $t0, -2032($t5)
	        sw $t0, -2300($t5)
	        sw $t0, -2296($t5)
	        sw $t0, -2292($t5)
		
		add, $t5, $t5, $a0	#move character
		
		#pants
	        li $t0, c_blue		
	        sw $t0, 0($t5)
	        sw $t0, -256($t5)
	        sw $t0, -252($t5)
	        sw $t0, -248($t5)
	        sw $t0, -244($t5)
	        sw $t0, 12($t5) 
	        
	        #shirt
	        li $t0, c_purple
	        sw $t0, -512($t5) 
	        sw $t0, -508($t5)
	        sw $t0, -504($t5)
	        sw $t0, -500($t5)
	        sw $t0, -768($t5) 
	        sw $t0, -764($t5)
	        sw $t0, -760($t5)
	        sw $t0, -756($t5)
	        sw $t0, -1024($t5) 
	        sw $t0, -1020($t5)
	        sw $t0, -1016($t5)
	        sw $t0, -1012($t5)
	        
	        
	        #arms
	        li $t0, c_skin
	        sw $t0, -516($t5) 	#left
	        sw $t0, -772($t5)	#right
	        sw $t0, -496($t5)
	        sw $t0, -752($t5)
	        
	        #hair
	        li $t0, black
	        sw $t0, -1028($t5)
	        sw $t0, -1032($t5)
	        sw $t0, -1036($t5)
	        sw $t0, -1284($t5)
	        sw $t0, -1288($t5)
	        sw $t0, -1292($t5)
	        sw $t0, -1540($t5)
	        sw $t0, -1544($t5)
	        sw $t0, -1796($t5)
	        sw $t0, -1800($t5)
	        sw $t0, -2052($t5)
	        sw $t0, -2308($t5)
	        sw $t0, -2304($t5)
	        sw $t0, -2560($t5)
	        sw $t0, -2556($t5)
	        sw $t0, -2552($t5)
	        sw $t0, -2548($t5)
	        sw $t0, -2544($t5)
	        sw $t0, -2288($t5)
	        sw $t0, -2284($t5)
	        sw $t0, -2028($t5)
	        sw $t0, -1772($t5)
	        sw $t0, -1516($t5)
	        sw $t0, -1260($t5)
	        sw $t0, -1004($t5)
	        sw $t0, -1008($t5)
	        
	        #face
	        sw $t0, -1788($t5)
	        sw $t0, -1780($t5)
	        li $t0, c_skin
	        sw $t0, -1784($t5)
	        sw $t0, -1792($t5)
	        sw $t0, -1776($t5)
	        sw $t0, -1280($t5)
	        sw $t0, -1276($t5)
	        sw $t0, -1272($t5)
	        sw $t0, -1268($t5)
	        sw $t0, -1264($t5)
	        sw $t0, -1536($t5)
	        sw $t0, -1532($t5)
	        sw $t0, -1528($t5)
	        sw $t0, -1524($t5)
	        sw $t0, -1520($t5)
	        sw $t0, -2048($t5)
	        sw $t0, -2044($t5)
	        sw $t0, -2040($t5)
	        sw $t0, -2036($t5)
	        sw $t0, -2032($t5)
	        sw $t0, -2300($t5)
	        sw $t0, -2296($t5)
	        sw $t0, -2292($t5)
	        
		jr $ra
		
draw_level:
	#draw bottom level
	li $t0, platform_d
	li $t1, floor
	li $t6, 256 		#64*4 units
bottom:	sw $t0, 0($t1)
	addi $t1, $t1, 4
	addi $t6, $t6, -1
	bnez $t6, bottom
	
	#draw platforms
#draw_platform: #takes an arguments position, size for the platform it will draw where position is the
		#address of the top left corner of the platform and size is the length in framebuffer units
	
	#draw goal
	
	
	#draw health
	jr $ra

#draw_platform: #takes an arguments position, size for the platform it will draw where position is the
		#address of the top left corner of the platform and size is the length in framebuffer units 
	#li $t0, platform_l
	#move $t1, $a0
	#li $t2, units
	#mult $a1, $t2
	#mflo $t6
	#sw $t0, 0($t1)
	#addi $t1, $t1, 4
	#addi $t6, $t6, -1
	#bnez $t6, draw_platform
	
end:	li $v0, 10 # terminate the program gracefully
	syscall














