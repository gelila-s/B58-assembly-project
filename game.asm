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
# - Milestone 3 
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. levels
# 2. moving objects
# 3. fail condition
# 4. win condition
# 5. health
# 6. double jump
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# -no
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

.eqv alive 			1
.eqv dead			0

#COLOURS		
.eqv black		0x000000
	#character
.eqv c_blue		0x3f51b5
.eqv c_purple		0x9c27b0
.eqv c_skin		0xc68642
	#enemies
.eqv e_body		0x009687
#.eqv e_eye_dark		0xd1c4e9
.eqv e_eye		0xede7f6
	#setting
.eqv background		0x9e9e9e
.eqv goal_c		0xffeb3b
.eqv heart_c		0xc62828  
#.eqv platform_l		0x607d8b
.eqv platform		0x546e7a

.data
#position:	.word 	0x1000BF00  #s0
health: 	.word 	3
#direction: 	.word 	0
#enemies:	.word	0:7
double_jump: 	.word	0:1

level: 		.word 	0:4096
current_level:  .word   1

#level one values
#platforms: 	.word 	0:8 	#even indices are the top left corner of the platform, odd indices are the size of the
				#platform at the index before (ex. a platform starts at platforms[0] and is 
				#platforms[1] units long
#enemies:	.word   0:4	#enemies[0] is the address of the enemy on platform[0]
				
#enemy2:	.word	0:5	#enemy[0] is the alive status of the enemy 0 = dead, 1 = alive
#enemy3:	.word 	0:5	#enemy[1] is the position of the enemy
				#enemy[2] is the left end of the platform it is on
				#enemy[3] is the right end of the platform it is on
				#enemy[4] is the direction the enemy is moving in, 0 for left, 1 for right
				
#level two values
#platforms: .word 	0:8 	
#enemies:	.word   0:4	

#enemy1_lvl2:	.word	0:5			
#enemy2:	.word	0:5	
##enemy3:	.word 	0:5

#level three values
#platforms: .word 	0:8 	
#enemies:	.word   0:4	

#enemy1_lvl3:	.word	0:5			
#enemy2:	.word	0:5	
#enemy3:	.word 	0:5


#level values
platforms: 	.word 	0:8 	
enemies:	.word   0:4	

enemy1:		.word	0:5			
enemy2:		.word	0:5	
enemy3:		.word 	0:5

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
	
	#draw floor
	li $t0, platform
	li $t1, floor
	li $t6, 256 		#64*4 units
bottom:	sw $t0, 0($t1)

	addi $t1, $t1, 4
	addi $t6, $t6, -1
	bnez $t6, bottom
	
	
	#draw health
	#li $t0, 3
	#sw $t0, health 		#set health to 3
	jal draw_health
	
	#store initial position in memory
	li $s0, above_floor
	addi $s0, $s0, 20
	#sw $s0, position	#update position
	#initial state
	li $a0, 0
	jal redraw_character
	
	
	lw $t0, current_level
	beq $t0, 3, lvl3	#jump to level 3
	beq $t0, 2, lvl2	#jump to level 2
	j lvl1			#otherwise level one
		

	
	
main_loop:
	jal enemy_contact
	
	#la $a0, enemies #load enemies as argument for move_enemies
	jal move_enemies
	jal check_win
	
	#Check for keyboard input.
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened
	
	#Figure out if the player character is standing on a platform.
		#check if either foot is above a unit with colour platform
		#left foot is at position, right foot is at position+8
		
	jal on_ground
	beq $v0, 1, sleep
	
	j gravity	#if player isnt on a platform, gravity to bottom row
	
	
	j sleep
	
   
	
	
keypress_happened:
	lw $t4, 4($t9)
	beq $t4, 0x61, respond_to_a
	beq $t4, 0x64, respond_to_d
	beq $t4, 0x77, respond_to_w
	beq $t4, 0x70, restart_game 	 
	j main_loop
	
	
respond_to_a: 
	#li $t1, 1		#change direction
	#sw $t1, direction
	li $a0, -4
	li $t1, 256
	subi $t2, $s0, BASE_ADDRESS #get offset from base address
	subi $t2, $t2, 8
	div $t2, $t1	
	mfhi $t1		#t2 = $s0 mod 256
	beq $t1, $zero, sleep   #if at edge dont move
	jal redraw_character 
	j sleep
	
respond_to_d: 
	#li $t1, 0		#change direction
	#sw $t1, direction
	li $a0, 4
	li $t1, 256
	subi $t2, $s0, BASE_ADDRESS #get offset from base address
	addi $t2, $t2, 20
	div $t2, $t1	
	mfhi $t1		#t2 = ($s0+1) mod 256
	beq $t1, $zero, sleep   #if at edge dont move
	jal redraw_character
	j sleep
	
respond_to_w: 
	#should only happen if the character is on a platform (or double jump)
	li $s1, jump_amount	#t9=number of pixels to be jumped
	li $s2, 256	#one row less than t9

	blt $s0, top_row, sleep #don't move past the top of the screen
	jal on_ground		#check if player is currently on the ground
	beq $v0, $zero, sleep   #if not, sleep
#	add $s0, $s0, $t1	#check if the character is a jump away from some platform
#	ble $s0, bottom_right_corner, dj
#	sub $s0, $s0, $t1	#restoring player position
#	j sleep
#dj:	jal on_ground
#	sw $v0, double_jump	#set double_jump to 0 if no, 1 if yes
#	sub $s0, $s0, $t1	#restoring player position
#	beq $v0, $t2, sleep	#dont jump in midair unless double jump	
jump:
	li $v0, 32	#wait for a second to give chance for double jump
	li $a0, 20
	syscall

	li $a0, -256
	jal redraw_character
	#la $a0, enemies #load enemies as argument for move_enemies
	jal move_enemies
	jal enemy_contact
	beq $v1, 1, gravity	#end jump if enemy hit
	subi $s1, $s1, 256
	bgt $s1, $s2, dj	#check for double jump
	bnez $s1, jump
	j sleep
dj:	li $t7, 0xffff0000	#check for second keypress (double jump)
	lw $t6, 0($t7)
	beq $t6, 0, jump		#if no second keypress, single jump
	lw $t4, 4($t7)
	bne $t4, 0x77, jump	#if second keypress wasn't a w, single jump
	sll $s1, $s1, 1		#otherwise, double the jump amount
	move $s2, $s1
	j jump			#go back to jump

gravity:
	li $a0, 256
	#sw $zero, double_jump
	jal redraw_character
	j sleep
	
check_win: #checks if the player has won
	move $t0, $s0		#t0 holds character position
	add $t0, $t0, $zero 	#start from bottom corner of side of body
	addi $t2, $t0, -512	#end at top corner of side of body
win_cond:
	lw $t1, -4($t0) 	#check bit beside left side of body
	beq $t1, goal_c, next_level #replace end with win screen
	lw $t1, 12($t0) 	#check bit beside right side of body
	beq $t1, goal_c, next_level #replace end with win screen
	beq $t0, $t2, no_win
	addi $t0, $t0, -256
	j win_cond 
no_win:	jr $ra
next_level:
	lw $t0, current_level
	addi $t0, $t0, 1	#go to next level
	sw $t0, current_level
	ble $t0, 3, main	#if level 1, 2, or 3 go to main
	j win			#otherwise win


enemy_contact:
	li $v1, 0		#reset return value
	#check for contact - if yes, hit
	lw $t0, -780($s0)	#beside bottom row
	beq $t0, e_body, hit
	lw $t0, -748($s0)
	beq $t0, e_body, hit
	lw $t0, -2056($s0)	#beside bottom row
	beq $t0, e_body, hit
	lw $t0, -2032($s0)
	beq $t0, e_body, hit
	lw $t0, -2044($s0)	#beside bottom row
	beq $t0, e_body, hit
	
	
	#check legs for contact - if yes, kill
#	lw $t0, 256($s0)
#	beq $t0, e_body, kill      
#	lw $t0, 264($s0) 
#	beq $t0, e_body, kill 
	#if none, jump back
	jr $ra
	
hit:	#redraw character entirely in red
	#pants
	        li $t0, 0xff0000		
	        sw $t0, 0($s0)
	        sw $t0, 8($s0) 
  
	        #shirt
	        sw $t0, -256($s0)	#row above feet
	        sw $t0, -252($s0)
	        sw $t0, -248($s0)
	        sw $t0, -512($s0) 	#row 2 above feet
	        sw $t0, -508($s0)
	        sw $t0, -504($s0)
	        
	        #hair
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
	        
	#decrease health
	lw $t0, health
	subi $t0, $t0, 1
	sw $t0, health	
				
	#erase heart
	li $t1, BASE_ADDRESS
	addi $t1, $t1, 264
	beq $t0, 2, erase_h3
	beq $t0, 1, erase_h2			
	beq $t0, $zero, erase_h

erase_h3:
	addi $t1, $t1, 32	
erase_h2:
	addi $t1, $t1, 32	
	
erase_h:li $t2, background	
	sw $t2, ($t1)		#top row
	sw $t2, 4($t1)
	sw $t2, 12($t1)
	sw $t2, 16($t1)
	
	sw $t2, 252($t1) 	#second row
	sw $t2, 256($t1)
	sw $t2, 260($t1)
	sw $t2, 264($t1)
	sw $t2, 268($t1)
	sw $t2, 272($t1)
	sw $t2, 276($t1)
	
	sw $t2, 508($t1) 	#third row
	sw $t2, 512($t1)
	sw $t2, 516($t1)
	sw $t2, 520($t1)
	sw $t2, 524($t1)
	sw $t2, 528($t1)
	sw $t2, 532($t1)
	
	sw $t2, 768($t1) 	#fourth row
	sw $t2, 772($t1)
	sw $t2, 776($t1)
	sw $t2, 780($t1)
	sw $t2, 784($t1)
	
	sw $t2, 1028($t1)	#fifth row
	sw $t2, 1032($t1)
	sw $t2, 1036($t1)
	
	sw $t2, 1288($t1)
	
	#update the level array
	sub $t5, $t1, BASE_ADDRESS #calculate offset from first pixel
	la $t6, level
	add $t1, $t6, $t5	   #t6 = level[start_pixel]
	
	sw $t2, ($t1)		#top row
	sw $t2, 4($t1)
	sw $t2, 12($t1)
	sw $t2, 16($t1)
	
	sw $t2, 252($t1) 	#second row
	sw $t2, 256($t1)
	sw $t2, 260($t1)
	sw $t2, 264($t1)
	sw $t2, 268($t1)
	sw $t2, 272($t1)
	sw $t2, 276($t1)
	
	sw $t2, 508($t1) 	#third row
	sw $t2, 512($t1)
	sw $t2, 516($t1)
	sw $t2, 520($t1)
	sw $t2, 524($t1)
	sw $t2, 528($t1)
	sw $t2, 532($t1)
	
	sw $t2, 768($t1) 	#fourth row
	sw $t2, 772($t1)
	sw $t2, 776($t1)
	sw $t2, 780($t1)
	sw $t2, 784($t1)
	
	sw $t2, 1028($t1)	#fifth row
	sw $t2, 1032($t1)
	sw $t2, 1036($t1)
	
	sw $t2, 1288($t1)

	li $v0, 32
	li $a0, 200
	syscall
	
	beq $t0, $zero, lose
	
	#move enemy one in the opposite direction
	la $t8, enemy2
change_enemy:
	li $t5, 4	#for calculating offset
	lw $t1, 16($t8) 	#t1 = enemy2 direction
	beq $t1, 1, ml
	lw $t1, 4($t8)		#move one right
	andi $t2, $t1, 3	#t2 = t1 mod 4
	sub $t2, $t5, $t2
	subi $t2, $t2, 1
	sub $t1, $t1, $t2
	sw $t1, 4($t8)
	addi $t2, $zero, 1	#change direction to right
	sw $t2, 16($t8)
	
	#move enemies
	addi $sp, $sp, -4	#store $ra
	sw $ra, ($sp)
	jal move_enemies
	lw $ra, ($sp)
	addi $sp, $sp, 4	#pop $ra
	
	
	la $t3, enemy3
	beq $t8, $t3, rd	#if done for enemy2, move to 
	j ce3	#now do it for enemy3
ml:  	lw $t1, 4($t8)		#move one left
	andi $t2, $t1, 3	#t2 = t1 mod 4
	sub $t2, $t5, $t2
	addi $t2, $t2, 1
	add $t1, $t1, $t2
	sw $t1, 4($t8)
	move $t2, $zero		#change direction to left
	sw $t2, 16($t8)
	
	#move enemies
	addi $sp, $sp, -4	#store $ra
	sw $ra, ($sp)
	jal move_enemies
	lw $ra, ($sp)
	addi $sp, $sp, 4	#pop $ra
	
	
	beq $t8, $t3, rd
ce3:	la $t8, enemy3
	j change_enemy
	
	#redraw in normal colours
rd:	addi $sp, $sp, -4	#store $ra
	sw $ra, ($sp)
	move $a0, $zero
	jal redraw_character
	lw $ra, ($sp)
	addi $sp, $sp, 4	#pop $ra
	
	li $v1, 1		#return 1 if hit (for jump function)
	
	jr $ra
	
	
	
	#lower health by 1, if health is 0 game over
	
#kill:	#erase enemy and set alive status to dead
#	la $t0, enemies
#	add $t2, $t0, 16 #end of enemies array
#e_loop:	lw $t1, ($t0)
#	bne $zero, $t1, check_if_killed
#	add $t0, $t0, 4
#	bne $t0, $t2, e_loop	#check until the end of enemies
#	jr $ra
	
#check_if_killed:
#	lw $t3, 4($t1)		#t3 = position of enemy at t1
#	add $t4, $s0, 1544 	#t4 = potential pos of enemy
#	beq $t3, $t4, set_dead
#	add $t4, $s0, 1540 	#t4 = potential pos of enemy
#	beq $t3, $t4, set_dead
#	add $t4, $s0, 1536
#	beq $t3, $t4, set_dead
#	add $t4, $s0, 1532
#	beq $t3, $t4, set_dead
#	add $t4, $s0, 1528
#	beq $t3, $t4, set_dead
#	add $t4, $s0, 1524
##	beq $t3, $t4, set_dead
#	add $t4, $s0, 1520
#	beq $t3, $t4, set_dead
#	add $t0, $t0, 4
#	bne $t0, $t2, e_loop	#check until the end of enemies
#	jr $ra
#set_dead: #erase and set dead the enemy at t1
#	sw $zero, ($t1) 	#set dead
	#erase old enemy
	
	


on_ground: #returns 1 if it's on a platform/ground, 0 if not
	move $t0, $s0
	addi $t0, $t0, 256 	#t0 = pixel under left foot
	lw $t1, ($t0)		#t1 = colour of t0
	beq $t1, platform, true	#if it's a platform/floor, react
	addi $t0, $t0, 8	#t0 = pixel under right foot
	lw $t1, ($t0)		#t1 = colour of t0
	beq $t1, platform, true#if it's a platform/floor, react
false:	li $v0, 0
	jr $ra	
true:	li $v0, 1
	jr $ra




move_enemies:	#takes the enemies list and corresponding platforms list as arguments
		#moves the enemies one unit left or one unit right depending on position
	la $t0, enemies
	lw $t1, 4($t0)  #t1 = addr(enemy2)
	lw $t2, ($t1)
	
moving:	lw $t2, 4($t1)  #t2 = position of enemy
	lw $t3, 16($t1) #t3 = direction fo the enemy
	
	beq $t3, 1, e_right 	#if direction = 1 move right
	subi $t5, $t2, 1    	#otherwise move left
	addi $t2, $t2, 3	#store the old position
	lw $t4, 8($t1)		#t4 = position of start of platform
	bge $t5, $t4, e_move #if we're not at the start of the platform, continue
	li $t3, 1		#if we are at the start of the platform, switch direction
	sw $t3, 16($t1)		#store new direction
	jr $ra		#and dont move
	
e_right:addi $t5, $t2, 1 #move position one byte right (1/4 a word)
	subi $t2, $t2, 3 #store old position
	lw $t4, 12($t1)		#t4 = position of end of platform
	blt $t5, $t4, e_move #if we're not at the end of the platform, continue
	sw $zero, 16($t1)		#if we are, store new direction
	jr $ra				#and don't move
	
e_move:	sw $t5, 4($t1)  	#update enemy's position in data
	andi $t4, $t5, 3 	#t4 = t5 mod 4
	beq $t4, 0, draw_enemies #if t5 is a multiple of 4, draw enemy at new position
	#go to next enemy
	#la $t0, ($a0)	#$t0 = addr(enemies)
	lw $t6, 8($t0)  #t1 = addr(enemy3)
	beq $t6, $t1, no_move	#if we've just finished e3, stop
	move $t1, $t6
	lw $t2, ($t1)
	beq $t2, 1, moving	#if alive, move
no_move:jr $ra		#otherwise jump back to caller
	
draw_enemies:
	#erase old enemy
	li $t9, background	
	sw $t9, ($t2)
	#legs
	sw $t9, -4($t2)
	sw $t9, ($t2)		
	sw $t9, 8($t2)
	sw $t9, 16($t2)
	sw $t9, 20($t2)
	#body
	sw $t9, -260($t2)
	sw $t9, -256($t2)	#bottom	
	sw $t9, -252($t2)
	sw $t9, -248($t2)
	sw $t9, -244($t2)		
	sw $t9, -240($t2)
	sw $t9, -236($t2)
	
	sw $t9, -512($t2)	#left side
	sw $t9, -768($t2)
	sw $t9, -1024($t2)
	sw $t9, -516($t2)	#left side
	sw $t9, -772($t2)
	sw $t9, -1028($t2)
			
	sw $t9, -496($t2)	#right side
	sw $t9, -752($t2)
	sw $t9, -1008($t2)
	sw $t9, -492($t2)	#right side
	sw $t9, -748($t2)
	sw $t9, -1004($t2)
	
	sw $t9, -1276($t2)	#top
	sw $t9, -1272($t2)
	sw $t9, -1268($t2)
	sw $t9, -1280($t2)	#top
	sw $t9, -1264($t2)	
	
	#eye
	sw $t9, -508($t2)	#left side
	sw $t9, -764($t2)
	sw $t9, -1020($t2)
			
	sw $t9, -500($t2)	#right side
	sw $t9, -756($t2)
	sw $t9, -1012($t2)
	
	sw $t9, -504($t2)	#middle
	sw $zero, -760($t2)
	sw $t9, -1016($t2)
	
	#redraw
	li $t9, e_body 		
	#legs
	sw $t9, ($t5)		
	sw $t9, 8($t5)
	sw $t9, 16($t5)
	#body
	sw $t9, -256($t5)	#bottom row		
	sw $t9, -252($t5)
	sw $t9, -248($t5)
	sw $t9, -244($t5)		
	sw $t9, -240($t5)
	
	sw $t9, -512($t5)	#left side
	sw $t9, -768($t5)
	sw $t9, -1024($t5)
			
	sw $t9, -496($t5)	#right side
	sw $t9, -752($t5)
	sw $t9, -1008($t5)
	
	sw $t9, -1276($t5)	#top
	sw $t9, -1272($t5)
	sw $t9, -1268($t5)	
	
	#eye
	li $t9, e_eye
	sw $t9, -508($t5)	#left side
	sw $t9, -764($t5)
	sw $t9, -1020($t5)
			
	sw $t9, -500($t5)	#right side
	sw $t9, -756($t5)
	sw $t9, -1012($t5)
	
	sw $t9, -504($t5)	#middle
	sw $zero, -760($t5)
	sw $t9, -1016($t5)

	lw $t6, 8($t0)  #t1 = addr(enemy3)
	beq $t6, $t1, no_move	#if we've just finished e3, stop
	move $t1, $t6
	lw $t2, ($t1)
	beq $t2, 1, moving	#if alive, move

	jr $ra 
	
erase_enemy:
	#erase old enemy at pos $a0
	move $t2, $a0
	li $t9, background	
	sw $t9, ($t2)
	#legs
	sw $t9, ($t2)		
	sw $t9, 8($t2)
	sw $t9, 16($t2)
	#body
	sw $t9, -256($t2)	#bottom	
	sw $t9, -252($t2)
	sw $t9, -248($t2)
	sw $t9, -244($t2)		
	sw $t9, -240($t2)
	
	sw $t9, -512($t2)	#left side
	sw $t9, -768($t2)
	sw $t9, -1024($t2)
			
	sw $t9, -496($t2)	#right side
	sw $t9, -752($t2)
	sw $t9, -1008($t2)
	
	sw $t9, -1276($t2)	#top
	sw $t9, -1272($t2)
	sw $t9, -1268($t2)	
	
	#eye
	sw $t9, -508($t2)	#left side
	sw $t9, -764($t2)
	sw $t9, -1020($t2)
			
	sw $t9, -500($t2)	#right side
	sw $t9, -756($t2)
	sw $t9, -1012($t2)
	
	sw $t9, -504($t2)	#middle
	sw $zero, -760($t2)
	sw $t9, -1016($t2)
	
	jr $ra


draw_health:
	la $t0, health		#get the number of health
	lw $t0, ($t0)
	li $t1, BASE_ADDRESS
	addi $t1, $t1, 264	#first heart location
	li $t2, heart_c	
	
	la $t6, level
	addi $t6, $t6, 264	   #t6 = level[start_pixel]	
	
draw_heart:
	sw $t2, ($t1)		#top row
	sw $t2, 4($t1)
	sw $t2, 12($t1)
	sw $t2, 16($t1)
	
	sw $t2, 252($t1) 	#second row
	sw $t2, 256($t1)
	sw $t2, 260($t1)
	sw $t2, 264($t1)
	sw $t2, 268($t1)
	sw $t2, 272($t1)
	sw $t2, 276($t1)
	
	sw $t2, 508($t1) 	#third row
	sw $t2, 512($t1)
	sw $t2, 516($t1)
	sw $t2, 520($t1)
	sw $t2, 524($t1)
	sw $t2, 528($t1)
	sw $t2, 532($t1)
	
	sw $t2, 768($t1) 	#fourth row
	sw $t2, 772($t1)
	sw $t2, 776($t1)
	sw $t2, 780($t1)
	sw $t2, 784($t1)
	
	sw $t2, 1028($t1)	#fifth row
	sw $t2, 1032($t1)
	sw $t2, 1036($t1)
	
	sw $t2, 1288($t1)	#sixth row
	
	#add values to the level array
	sw $t2, ($t6)		#top row
	sw $t2, 4($t6)
	sw $t2, 12($t6)
	sw $t2, 16($t6)
	
	sw $t2, 252($t6) 	#second row
	sw $t2, 256($t6)
	sw $t2, 260($t6)
	sw $t2, 264($t6)
	sw $t2, 268($t6)
	sw $t2, 272($t6)
	sw $t2, 276($t6)
	
	sw $t2, 508($t6) 	#third row
	sw $t2, 512($t6)
	sw $t2, 516($t6)
	sw $t2, 520($t6)
	sw $t2, 524($t6)
	sw $t2, 528($t6)
	sw $t2, 532($t6)
	
	sw $t2, 768($t6) 	#fourth row
	sw $t2, 772($t6)
	sw $t2, 776($t6)
	sw $t2, 780($t6)
	sw $t2, 784($t6)
	
	sw $t2, 1028($t6)	#fifth row
	sw $t2, 1032($t6)
	sw $t2, 1036($t6)
	
	sw $t2, 1288($t6)	#sixth row
	
	subi $t0, $t0, 1
	addi $t1, $t1, 32	#draw next heart 8 pixels to the right	
	addi $t6, $t6, 32	#move level pointer
	bnez $t0, draw_heart
	jr $ra


draw_goal: #takes three arguements a0 = top left corner of goal, a1 = length of goal, a2 = width of goal
	li $t0, goal_c		#load goal colour
	#li $t4, 4		#counter
	#addi $t1, $zero, BASE_ADDRESS
	#addi $t1, $t1, 2276	#start 1020 away from BASE_ADDRESS
	move $t1, $a0
	
	sub $t5, $t1, BASE_ADDRESS #calculate offset from first pixel
	la $t6, level
	add $t6, $t6, $t5	   #t6 = level[start_pixel]
	
	#li $t2, 9		#t2 = 6 is the height of the goal
	#li $t3, 6		#t3 = 6 is the width of the goal
	move $t2, $a1
	move $t3, $a2
goal_rp:sw $t0, 0($t1)		#draw one row of the platform
	sw $t0, ($t6)		#store colour in level
	addi $t1, $t1, 4
	addi $t6, $t6, 4	#move to next index in level array
	addi $t3, $t3, -1
	bnez $t3, goal_rp
	subi $t1, $t1, 24
	addi $t1, $t1, 256
	subi $t6, $t6, 24	#next row in level array
	addi $t6, $t6, 256	
	move $t3, $a2
	addi $t2, $t2, -1
	bnez $t2, goal_rp
	
	jr $ra	


draw_platforms: #draws platforms in defined in list at address provided as an argument
	li $t0, platform	#load platform colour
	li $t4, 4		#counter
draw_p:	lw $t1, ($a0)		#start drawing platform from t1 = $a0[0] = top left corner
	
	sub $t5, $t1, BASE_ADDRESS #calculate offset from first pixel
	la $t6, level
	add $t6, $t6, $t5	   #t6 = level[start_pixel]
	add $t5, $t6, $zero	   #t5 = level[start_pixel]
	
	#li $t2, 1		#t2 is the height of the platform
	lw $t3, 4($a0)		#t3 = $a0[1] = length of platform
row:	sw $t0, 0($t1)		#draw one row of the platform
	sw $t0, ($t6)		#store colour in level
	addi $t1, $t1, 4
	addi $t6, $t6, 4	#move to next index in level array
	addi $t3, $t3, -1
	bnez $t3, row
	#lw $t1, ($a0)		#move to next row of the platform
	#addi $t1, $t1, 256
	#addi $t6, $t5, 256	
	#lw $t3, 4($a0)
	#addi $t2, $t2, -1
	#bnez $t2, row
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
		
lvl1:	#set up list of platforms
	la $t0, platforms	#get address of the array
	
	 #first platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 4544
	
	sw $t1, ($t0)		#store the first platform's address
	addi $t0, $t0, 4
	li $t1, 16
	sw $t1, ($t0)		#store the first platform's width
	
	 #second platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 6716
	addi $t0, $t0, 4
	sw $t1 ($t0)		#store the second platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the second platform's width
	
	 #third platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 10140
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the third platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the third platform's width
	
	 #fourth platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 12620
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the fourth platform's address
	addi $t0, $t0, 4
	li $t1, 16
	sw $t1, ($t0)		#store the fourth platform's width
	
	 #draw the platforms
	la $a0, platforms	#argument is platforms
	jal draw_platforms	#call function
	
	
	
	#fill out the details of enemy2
	la $t0, enemies	#load adresses
	la $t1, enemy2
	sw $t1, 4($t0)	#store the address of enemy2 in enemies[1] (second element of the array)
	
	la $t2, platforms
	
	li $t0, alive	#set status to alive
	sw $t0, ($t1)	
	lw $t0, 8($t2)  #t0 = position of platform2
	subi $t0, $t0, 256  #set enemy2 on top of platform2
	sw $t0, 4($t1)	#set enemy2 position
	sw $t0, 8($t1) 	#set left side of platform2
	lw $t3, 12($t2) #get length of platform2
	sll $t3, $t3, 2 #multiply length by 4
	subi $t3, $t3, 16
	add $t0, $t0, $t3 #add length to start of platform to get end of platform
	sw $t0, 12($t1)	#set position of right side of platform2
	li $t0, 1
	sw $t0, 16($t1) #set direction to right
	
	#fill out the details of enemy3
	la $t0, enemies	#load adresses
	la $t1, enemy3
	sw $t1, 8($t0)	#store the address of enemy3 in enemies[2] (third element of the array)
	
	la $t2, platforms
	
	li $t0, alive	#set status to alive
	sw $t0, ($t1)	
	lw $t0, 16($t2)  #t0 = position of platform3
	subi $t0, $t0, 256  #set enemy2 on top of platform3
	sw $t0, 4($t1)	#set enemy3 position
	sw $t0, 8($t1) 	#set left side of platform3
	lw $t3, 20($t2) #get length of platform3
	sll $t3, $t3, 2 #multiply length by 4
	subi $t3, $t3, 16 #subtract length of the enemy
	add $t0, $t0, $t3 #add length to start of platform to get end of platform
	sw $t0, 12($t1)	#set position of right side of platform2
	li $t0, 1
	sw $t0, 16($t1) #set direction to right
	
	#draw goal
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 2276
	li $a1, 9
	li $a2, 6
	jal draw_goal
	
	j main_loop
	
lvl2:	la $t0, platforms	#get address of the array
	
	 #first platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 4544
	
	sw $t1, ($t0)		#store the first platform's address
	addi $t0, $t0, 4
	li $t1, 16
	sw $t1, ($t0)		#store the first platform's width
	
	 #second platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 7580
	addi $t0, $t0, 4
	sw $t1 ($t0)		#store the second platform's address
	addi $t0, $t0, 4
	li $t1, 16
	sw $t1, ($t0)		#store the second platform's width
	
	 #third platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 9728
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the third platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the third platform's width
	
	 #fourth platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 13432
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the fourth platform's address
	addi $t0, $t0, 4
	li $t1, 8
	sw $t1, ($t0)		#store the fourth platform's width
	
	 #draw the platforms
	la $a0, platforms	#argument is platforms
	jal draw_platforms	#call function
	
	
	
	#fill out the details of enemy2
	la $t0, enemies	#load adresses
	la $t1, enemy2
	sw $t1, 4($t0)	#store the address of enemy2 in enemies[1] (second element of the array)
	
	la $t2, platforms
	
	li $t0, alive	#set status to alive
	sw $t0, ($t1)	
	lw $t0, 8($t2)  #t0 = position of platform2
	subi $t0, $t0, 256  #set enemy2 on top of platform2
	sw $t0, 4($t1)	#set enemy2 position
	sw $t0, 8($t1) 	#set left side of platform2
	lw $t3, 12($t2) #get length of platform2
	sll $t3, $t3, 2 #multiply length by 4
	subi $t3, $t3, 16
	add $t0, $t0, $t3 #add length to start of platform to get end of platform
	sw $t0, 12($t1)	#set position of right side of platform2
	li $t0, 1
	sw $t0, 16($t1) #set direction to right
	
	#fill out the details of enemy3
	la $t0, enemies	#load adresses
	la $t1, enemy3
	sw $t1, 8($t0)	#store the address of enemy3 in enemies[2] (third element of the array)
	
	la $t2, platforms
	
	li $t0, alive	#set status to alive
	sw $t0, ($t1)	
	lw $t0, 16($t2)  #t0 = position of platform3
	subi $t0, $t0, 256  #set enemy2 on top of platform3
	sw $t0, 4($t1)	#set enemy3 position
	sw $t0, 8($t1) 	#set left side of platform3
	lw $t3, 20($t2) #get length of platform3
	sll $t3, $t3, 2 #multiply length by 4
	subi $t3, $t3, 16 #subtract length of the enemy
	add $t0, $t0, $t3 #add length to start of platform to get end of platform
	sw $t0, 12($t1)	#set position of right side of platform2
	li $t0, 1
	sw $t0, 16($t1) #set direction to right
	
	#draw goal
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 2276
	li $a1, 9
	li $a2, 6
	jal draw_goal
	
	j main_loop	
	
lvl3:	la $t0, platforms	#get address of the array
	
	 #first platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 2992
	sw $t1, ($t0)		#store the first platform's address
	addi $t0, $t0, 4
	li $t1, 20
	sw $t1, ($t0)		#store the first platform's width
	
	 #second platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 6664
	addi $t0, $t0, 4
	sw $t1 ($t0)		#store the second platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the second platform's width
	
	 #third platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 9628
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the third platform's address
	addi $t0, $t0, 4
	li $t1, 24
	sw $t1, ($t0)		#store the third platform's width
	
	 #fourth platform
	li $t1, BASE_ADDRESS	
	addi $t1, $t1, 13368
	addi $t0, $t0, 4
	sw $t1, ($t0)		#store the fourth platform's address
	addi $t0, $t0, 4
	li $t1, 12
	sw $t1, ($t0)		#store the fourth platform's width
	
	 #draw the platforms
	la $a0, platforms	#argument is platforms
	jal draw_platforms	#call function
	
	
	
	#fill out the details of enemy2
	la $t0, enemies	#load adresses
	la $t1, enemy2
	sw $t1, 4($t0)	#store the address of enemy2 in enemies[1] (second element of the array)
	
	la $t2, platforms
	
	li $t0, alive	#set status to alive
	sw $t0, ($t1)	
	lw $t0, 8($t2)  #t0 = position of platform2
	subi $t0, $t0, 256  #set enemy2 on top of platform2
	sw $t0, 4($t1)	#set enemy2 position
	sw $t0, 8($t1) 	#set left side of platform2
	lw $t3, 12($t2) #get length of platform2
	sll $t3, $t3, 2 #multiply length by 4
	subi $t3, $t3, 16
	add $t0, $t0, $t3 #add length to start of platform to get end of platform
	sw $t0, 12($t1)	#set position of right side of platform2
	li $t0, 1
	sw $t0, 16($t1) #set direction to right
	
	#fill out the details of enemy3
	la $t0, enemies	#load adresses
	la $t1, enemy3
	sw $t1, 8($t0)	#store the address of enemy3 in enemies[2] (third element of the array)
	
	la $t2, platforms
	
	li $t0, alive	#set status to alive
	sw $t0, ($t1)	
	lw $t0, 16($t2)  #t0 = position of platform3
	subi $t0, $t0, 256  #set enemy2 on top of platform3
	sw $t0, 4($t1)	#set enemy3 position
	sw $t0, 8($t1) 	#set left side of platform3
	lw $t3, 20($t2) #get length of platform3
	sll $t3, $t3, 2 #multiply length by 4
	subi $t3, $t3, 16 #subtract length of the enemy
	add $t0, $t0, $t3 #add length to start of platform to get end of platform
	sw $t0, 12($t1)	#set position of right side of platform2
	li $t0, 1
	sw $t0, 16($t1) #set direction to right
	
	#draw goal
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 740
	li $a1, 9
	li $a2, 6
	jal draw_goal
	
	j main_loop

restart_game:
	li $t0, 3
	sw $t0, health
	li $t0, 1
	sw $t0, current_level
	j main
	
	
lose:	#show game over screen
	li $t1, BASE_ADDRESS #start from top left corner
	li $t6, num_pixels
	li $t0, background
lose_bg:sw $t0, 0($t1)
	addi $t1, $t1, 4
	addi $t6, $t6, -1
	bnez $t6, lose_bg
		
	#write the words you lose
	li $t1, BASE_ADDRESS
	addi $t1, $t1, 5188   #start writing word here
	
	#Y
	sw $zero, ($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 516($t1)
	sw $zero, 520($t1)
	sw $zero, 772($t1)
	sw $zero, 1028($t1)
	#O
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 520($t1)
	sw $zero, 768($t1)
	sw $zero, 776($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	#U
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 520($t1)
	sw $zero, 768($t1)
	sw $zero, 776($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	
	#L
	addi $t1, $t1, 32
	sw $zero, ($t1)
	sw $zero, 256($t1)
	sw $zero, 512($t1)
	sw $zero, 768($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	#O
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 520($t1)
	sw $zero, 768($t1)
	sw $zero, 776($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	#S
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 512($t1)
	sw $zero, 516($t1)
	sw $zero, 520($t1)
	sw $zero, 776($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	#E
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 512($t1)
	sw $zero, 516($t1)
	sw $zero, 768($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	
	#check for keypress p and restart game if so
	j check_restart
	
	
win:	#show win screen
	li $t1, BASE_ADDRESS #start from top left corner
	li $t6, num_pixels
	li $t0, background
win_bg:	sw $t0, 0($t1)
	addi $t1, $t1, 4
	addi $t6, $t6, -1
	bnez $t6, win_bg
	
	#write the words you win
	li $t1, BASE_ADDRESS
	addi $t1, $t1, 5192   #start writing word here
	
	#Y
	sw $zero, ($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 516($t1)
	sw $zero, 520($t1)
	sw $zero, 772($t1)
	sw $zero, 1028($t1)
	#O
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 520($t1)
	sw $zero, 768($t1)
	sw $zero, 776($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	#U
	addi $t1, $t1, 16
	sw $zero, ($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 520($t1)
	sw $zero, 768($t1)
	sw $zero, 776($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1032($t1)
	
	#W
	addi $t1, $t1, 32
	sw $zero, ($t1)
	sw $zero, 16($t1)
	sw $zero, 256($t1)
	sw $zero, 272($t1)
	sw $zero, 512($t1)
	sw $zero, 520($t1)
	sw $zero, 528($t1)
	sw $zero, 768($t1)
	sw $zero, 776($t1)
	sw $zero, 784($t1)
	sw $zero, 1024($t1)
	sw $zero, 1028($t1)
	sw $zero, 1036($t1)
	sw $zero, 1040($t1)
	#I
	addi $t1, $t1, 24
	sw $zero, ($t1)
	sw $zero, 256($t1)
	sw $zero, 512($t1)
	sw $zero, 768($t1)
	sw $zero, 1024($t1)
	#N
	addi $t1, $t1, 8
	sw $zero, ($t1)
	sw $zero, 256($t1)
	sw $zero, 260($t1)
	sw $zero, 512($t1)
	sw $zero, 516($t1)
	sw $zero, 768($t1)
	sw $zero, 1024($t1)
	addi $t1, $t1, 12
	sw $zero, ($t1)
	sw $zero, 256($t1)
	sw $zero, 512($t1)
	sw $zero, 508($t1)
	sw $zero, 768($t1)
	sw $zero, 764($t1)
	sw $zero, 1024($t1)
	
	j check_restart
	
check_restart:
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	bne $t8, 1, check_restart
	lw $t4, 4($t9)
	beq $t4, 0x70, restart_game 
	j check_restart
	
sleep:	
	li $v0, 32
	li $a0, 100
	syscall
	j main_loop
	
end:	li $v0, 10 # terminate the program gracefully
	syscall










