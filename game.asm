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
#.eqv units			64
.eqv bottom_left_corner		0x1000BF00
.eqv bottom_right_corner	0x1000BFFC
.eqv jump_amount		3328 		#units you want to jump * 256
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
#.eqv platform_l		0x607d8b
.eqv platform		0x546e7a

.data
position:	.word 	0x1000BF00  #s0
direction: 	.word 	0
enemies:	.word	0:7
double_jump: 	.word	0:1
platforms1: 	.word 	0:8 	#even indices are the top left corner of the platform, odd indices are the size of the
				#platform at the index before (ex. a platform starts at platforms1[0] and is 
				#platforms1[1] units long
level: 		.word 	0:4096


.text
#t0, t1 - temp variables, #t2 - character position
.globl main
main:
	#clear screen
	li $t1, BASE_ADDRESS #start from top left corner
	li $t6, num_pixels
	li $t0, background
	la $t2, level
clear:	sw $t0, 0($t1)
	sw $t0, 0($t2)
	addi $t1, $t1, 4
	addi $t2, $t2, 4
	addi $t6, $t6, -1
	bnez $t6, clear
	
#draw_level
	
	#draw bottom level
	li $t0, platform
	li $t1, floor
	li $t6, 256 		#64*4 units
bottom:	sw $t0, 0($t1)

	addi $t1, $t1, 4
	addi $t6, $t6, -1
	bnez $t6, bottom
	
	#set up list of platforms1
	la $t0, platforms1	#get address of the array
	
	 #first platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 12620
	sw $t1, ($t0)		#store the first platform's address
	addi $t0, $t0, 4
	li $t1, 16
	sw $t1, ($t0)		#store the first platform's width
	
	
	 #second platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 3264
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the second platform's address
	addi $t0, $t0, 4
	li $t1, 16
	sw $t1, ($t0)		#store the third platform's width
	
	 #third platform
	li $t1, BASE_ADDRESS	#platform3
	addi $t1, $t1, 6460
	addi $t0, $t0, 4
	sw $t1 ($t0)		#store the third platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the third platform's width
	
	 #fourth platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 10140
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the fourth platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the fourth platform's width
	
	 #draw the platforms
	la $a0, platforms1	#argument is platforms1
	jal draw_platforms	#call function
	
	#draw goal
	
	
	#draw health


	
	#store initial position in memory
	li $s0, above_floor
	addi $s0, $s0, 20
	sw $s0, position	#update position
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
		#check if either foot is above a unit with colour platform
		#left foot is at position, right foot is at position+8
	jal on_ground
	beq $v0, 1, main_loop
	
	#Update player location, enemies, platforms, power ups, etc.
	j gravity	#if player isnt on a platform, gravity to bottom row
	
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
	beq $t4, 0x6B, main 	 #respond_to_k
	j main_loop
	
	
respond_to_a: 
	li $t1, 1		#change direction
	sw $t1, direction
	li $a0, -4
	jal redraw_character
	j sleep
	
respond_to_d: 
	li $t1, 0		#change direction
	sw $t1, direction
	li $a0, 4
	jal redraw_character
	j sleep
	
respond_to_w: 
	#should only happen if the character is on a platform (or double jump)
	li $t9, jump_amount	#t1=number of pixels to be jumped
	blt $s0, top_row, sleep #don't move past the top of the screen
	jal on_ground		#check if player is currently on the ground
	beq $v0, $zero, sleep
#	add $s0, $s0, $t1	#check if the character is a jump away from some platform
#	ble $s0, bottom_right_corner, dj
#	sub $s0, $s0, $t1	#restoring player position
#	j sleep
#dj:	jal on_ground
#	sw $v0, double_jump	#set double_jump to 0 if no, 1 if yes
#	sub $s0, $s0, $t1	#restoring player position
#	beq $v0, $t2, sleep	#dont jump in midair unless double jump	
jump:
	li $a0, -256
	jal redraw_character
	subi $t9, $t9, 256
	bnez $t9, jump
	j sleep

gravity:
	li $a0, 256
	sw $zero, double_jump
	jal redraw_character
	j sleep
	
	
on_ground: #returns 1 if it's on a platform/ground, 0 if not
	move $t0, $s0
	addi $t0, $t0, 256 	#t0 = pixel under left foot
	lw $t1, ($t0)		#t1 = colour of t0
	beq $t1, platform, true	#if it's a platform/floor, react
	addi $t0, $t0, 12	#t0 = pixel under right foot
	lw $t1, ($t0)		#t1 = colour of t0
	bne $t1, platform, false#if it's a platform/floor, react
	addi $t0, $t0, 256	#t0 = pixel two under right foot
	lw $t1, ($t0)		#t1 = colour of t0
	beq $t1, platform, true	#if it's a platform/floor, react
	addi $t0, $t0, -12	#t0 = pixel two under left foot
	lw $t1, ($t0)		#t1 = colour of t0
	beq $t1, platform, true	#if it's a platform/floor, react
false:	li $v0, 0
	j return	
true:	li $v0, 1
return:	jr $ra

draw_platforms: #draws platforms in defined in list at address provided as an argument
	li $t0, platform	#load platform colour
	li $t4, 4		#counter
draw_p:	lw $t1, ($a0)		#start drawing platform from t1 = $a0[0] = top left corner
	
	sub $t5, $t1, BASE_ADDRESS #calculate offset from first pixel
	la $t6, level
	add $t6, $t6, $t5	   #t6 = level[start_pixel]
	add $t5, $t6, $zero	   #t5 = level[start_pixel]
	
	li $t2, 3		#3 is the height of the platform
	lw $t3, 4($a0)		#t3 = $a0[1] = length of platform
row:	sw $t0, 0($t1)		#draw one row of the platform
	sw $t0, ($t6)		#store colour in level
	addi $t1, $t1, 4
	addi $t6, $t6, 4	#move to next index in level array
	addi $t3, $t3, -1
	bnez $t3, row
	lw $t1, ($a0)		#move to next row of the platform
	addi $t1, $t1, 256
	addi $t6, $t5, 256	
	lw $t3, 4($a0)
	addi $t2, $t2, -1
	bnez $t2, row
	subi $t4, $t4, 1
	addi $a0, $a0, 8
	bnez $t4, draw_p	#move to next platform in list	
	
	jr $ra
	

	
redraw_character: #redraw(old pos, offset) erases the charater at old_pos and redraws at old_pos + offset
	          #position is the location of the bottom-most, left-most framebuffer unit of the character
	          #arguments provided using stack? a0-a3? position could be stored in memory after each move
	          
	        #check direction and jump to left or to right 
	        
	        sub $t1, $s0, BASE_ADDRESS #t1=diff btwn base an pos
	        la $t0, level
	        add $t1, $t1, $t0	   #t1 = level[pos]
	        
	        #pants	
	    	lw $t0, 0($t1)
	        sw $t0, 0($s0)
	        lw $t0, 8($t1)
	        sw $t0, 8($s0) 
	        #shirt
	        lw $t0, -256($t1)	#row above feet
	        sw $t0, -256($s0)
	        lw $t0, -252($t1)
	        sw $t0, -252($s0)
	        lw $t0, -248($t1)
	        sw $t0, -248($s0)
	        
	        lw $t0, -512($t1) 	#row 2 above feet
	        sw $t0, -512($s0) 
	        lw $t0, -508($t1) 
	        sw $t0, -508($s0)
	        lw $t0, -504($t1) 
	        sw $t0, -504($s0)
	        
	        #hair
	        lw $t0, -776($t1)	
	        sw $t0, -776($s0)
	        lw $t0, -752($t1)	
	        sw $t0, -752($s0)
	        lw $t0, -1032($t1)	#second row
	        sw $t0, -1032($s0)
	        lw $t0, -1008($t1)	
	        sw $t0, -1008($s0)
	        lw $t0, -1288($t1)	#third row
	        sw $t0, -1288($s0)	
	        lw $t0, -1264($t1)
	        sw $t0, -1264($s0)
	        lw $t0, -1544($t1)	#fourth row
	        sw $t0, -1544($s0)	
	        lw $t0, -1520($t1)
	        sw $t0, -1520($s0)
	        	
	        lw $t0, -1776($t1)	#top row
	        sw $t0, -1776($s0)
	        lw $t0, -1780($t1)
	        sw $t0, -1780($s0)
	        lw $t0, -1784($t1)
	        sw $t0, -1784($s0)
	        lw $t0, -1788($t1)
	        sw $t0, -1788($s0)
	        lw $t0, -1792($t1)
	        sw $t0, -1792($s0)
	        lw $t0, -1796($t1)
	        sw $t0, -1796($s0)
	        lw $t0, -1800($t1)
	        sw $t0, -1800($s0)
	
	        #face
	        lw $t0, -772($t1)	#bottom row
	        sw $t0, -772($s0) 
	        lw $t0, -768($t1) 
	        sw $t0, -768($s0) 
	        lw $t0, -764($t1) 
	        sw $t0, -764($s0)
	        lw $t0, -760($t1) 
	        sw $t0, -760($s0)
	        lw $t0, -756($t1) 
	        sw $t0, -756($s0)
	        
	        lw $t0, -1028($t1)	#second row
	        sw $t0, -1028($s0)
	        lw $t0, -1024($t1)
	        sw $t0, -1024($s0)
	        lw $t0, -1020($t1)
	        sw $t0, -1020($s0)
	        lw $t0, -1016($t1)
	        sw $t0, -1016($s0)
	        lw $t0, -1012($t1)
	        sw $t0, -1012($s0)
	        
	        lw $t0, -1284($t1)	#third row
	        sw $t0, -1284($s0)
	        lw $t0, -1280($t1)
	        sw $t0, -1280($s0)
	        lw $t0, -1276($t1)
	        sw $t0, -1276($s0)
	        lw $t0, -1272($t1)
	        sw $t0, -1272($s0)
	        lw $t0, -1268($t1)
	        sw $t0, -1268($s0)
	        
	        lw $t0, -1540($t1)	#fourth row
	        sw $t0, -1540($s0)
	        lw $t0, -1536($t1)
	        sw $t0, -1536($s0)
	        lw $t0, -1532($t1)
	        sw $t0, -1532($s0)
	        lw $t0, -1528($t1)
	        sw $t0, -1528($s0)
	        lw $t0, -1524($t1)
	        sw $t0, -1524($s0)
	
	   	#move character
		add, $s0, $s0, $a0	
	   	
	 
		
		#pants
	        li $t0, c_blue		
	        sw $t0, 0($s0)
	        #sw $t0, -256($s0)
	        #sw $t0, -252($s0)
	        #sw $t0, -248($s0)
	        #sw $t0, -244($s0)
	        sw $t0, 8($s0) 
	        
	        
	        #shirt
	        li $t0, c_purple
	        sw $t0, -256($s0)	#row above feet
	        sw $t0, -252($s0)
	        sw $t0, -248($s0)
	        sw $t0, -512($s0) 	#row 2 above feet
	        sw $t0, -508($s0)
	        sw $t0, -504($s0)
	        
	        #hair
	        li $t0, black
	        sw $t0, -776($s0)	#bottom row
	        sw $t0, -752($s0)
	        sw $t0, -1032($s0)	#second row
	        sw $t0, -1008($s0)
	        sw $t0, -1288($s0)	#third row
	        sw $t0, -1264($s0)
	        sw $t0, -1544($s0)	#fourth row
	        sw $t0, -1520($s0)
	        	
	        sw $t0, -1776($s0)	#top row
	        sw $t0, -1780($s0)
	        sw $t0, -1784($s0)
	        sw $t0, -1788($s0)
	        sw $t0, -1792($s0)
	        sw $t0, -1796($s0)
	        sw $t0, -1800($s0)
	        
	        #face
	        sw $t0, -1280($s0)	#eyes
	        sw $t0, -1272($s0)
	        
	        li $t0, c_skin
	        
	        sw $t0, -772($s0)	#bottom row of face
	        sw $t0, -768($s0)	
	        sw $t0, -764($s0)
	        sw $t0, -760($s0)
	        sw $t0, -756($s0)
	        
	        sw $t0, -1028($s0)	#second row of face
	        sw $t0, -1024($s0) 
	        sw $t0, -1020($s0)
	        sw $t0, -1016($s0)
	        sw $t0, -1012($s0)
	        
	        sw $t0, -1284($s0)	#third row of face
	        sw $t0, -1276($s0)
	        sw $t0, -1268($s0)

	        sw $t0, -1540($s0)	#fourth row of face
	        sw $t0, -1536($s0)	
	        sw $t0, -1532($s0)
	        sw $t0, -1528($s0)
	        sw $t0, -1524($s0)

	     
	        
	        #jump back to calling function	
		jr $ra
	
sleep:	
	li $v0, 32
	li $a0, 1
	syscall
	j main_loop
	
end:	li $v0, 10 # terminate the program gracefully
	syscall










