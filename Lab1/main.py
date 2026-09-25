from pyray import *

def main():
    # Initialize window: width, height, title
    init_window(800, 450, "Moisns game")
    set_target_fps(60)

    # Main game loop
    while not window_should_close():
        # Update game logic
        
        # Draw frame
        begin_drawing()
        clear_background(RAYWHITE)
        draw_text("Mohsin muhammad mustafa qureshi", 190, 200, 20, VIOLET)
        end_drawing()

    # Clean up resources
    close_window()

if __name__ == "__main__":
    main()