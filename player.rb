require "gosu/animator"
require "gosu/physics"

class Player
  def initialize(x, y, camera:)
    @width = 29
    @height = 55
    @physics_player = Gosu::Physics::BasePlayer.new(x, y, @width, @height)
    @animator = Gosu::Animator.new
    @last_action = :idle
    @current_action = :idle
    @direction = :right
    @camera = camera
    load_animations
    update_camera_position
  end

  def update(dt, obstacles)
    @last_action = @current_action
    @current_action = calculate_current_action
    p "="*100
    p "before gravity"
    log_player
    @physics_player.body.apply_gravity(dt)
    p "after gravity"
    log_player
    handle_collisions(obstacles)
    p "after collision"
    log_player
    p "="*100
    @physics_player.update(dt)
    update_animation
    update_direction
    update_camera_position
  end

  def button_down(id, dt)
    @physics_player.jump(dt) if id == Gosu::Button::KbSpace
  end

  def calculate_current_action
    if (@physics_player.body.speed_x > 10 || @physics_player.body.speed_x < -10) && @physics_player.body.speed_y.zero?
      :run
    elsif @physics_player.body.speed_y < -1
      :jump
    elsif @physics_player.body.speed_y > 1
      :fall
    else
      :idle
    end
  end

  def move_left(dt)
    @physics_player.move_left(dt)
  end

  def move_right(dt)
    @physics_player.move_right(dt)
  end

  # We draw the player in the middle of the window
  def draw
    if @direction == :left
      x = 400 + @width
      scale_x = -0.125
    else
      x = 400
      scale_x = 0.125
    end
    @animator.draw(@current_action, x, 300, scale_x: scale_x, scale_y: 0.125)
    #@physics_player.draw
  end

  private

  def log_player
    puts "Player position: #{@physics_player.body.x} - #{@physics_player.body.y}"
    puts "Player Velocity: #{@physics_player.body.speed_x} - #{@physics_player.body.speed_y}"
  end

  def update_camera_position
    @camera.map_position(-@physics_player.body.x, -@physics_player.body.y)
  end

  def load_animations
    base_animation_path = "./assets/png"
    run_animation_images = %w[Run__000.png Run__001.png Run__002.png Run__003.png Run__004.png Run__005.png Run__006.png Run__007.png Run__008.png Run__009.png]
    idle_animation_images = %w[Idle__000.png Idle__001.png Idle__002.png Idle__003.png Idle__004.png Idle__005.png Idle__006.png Idle__007.png Idle__008.png Idle__009.png]
    jump_animation_images = %w[Jump__000.png Jump__001.png Jump__002.png Jump__003.png Jump__004.png Jump__005.png Jump__006.png Jump__007.png Jump__008.png Jump__009.png]
    fall_animation_images = %w[Jump__009.png]

    run_animation_images.map! { |name| File.join(base_animation_path, name) }
    jump_animation_images.map! { |name| File.join(base_animation_path, name) }
    idle_animation_images.map! { |name| File.join(base_animation_path, name) }
    fall_animation_images.map! { |name| File.join(base_animation_path, name) }

    @animator << Gosu::Animation.new(:run, run_animation_images)
    @animator << Gosu::Animation.new(:jump, jump_animation_images, replay: false)
    @animator << Gosu::Animation.new(:idle, idle_animation_images)
    @animator << Gosu::Animation.new(:fall, fall_animation_images)
  end

  def update_direction
    @direction = @physics_player.body.speed_x.positive? ? :right : :left
  end

  def update_animation
    if @current_action == :jump && @last_action != :jump
      @animator.replay(:jump)
    elsif @current_action != @last_action
      @animator.play(@current_action)
    end

    @animator.update
  end

  def handle_collisions(obstacles)
    near_obstacles = obstacles.select do |obstacle|
      diff_x = @physics_player.body.x - obstacle.x
      diff_y = @physics_player.body.y - obstacle.y

      diff_x < 64 && diff_x > -64 && diff_y < 64 && diff_y > -64
    end

    near_obstacles.each do |obstacle|
      if @physics_player.body.collide?(obstacle)
        collision_direction = @physics_player.body.collision_direction(obstacle)

        case collision_direction
        when :bottom
          if @physics_player.body.speed_y > 0
            @physics_player.body.reset_speed_y
            p "collide bottom to #{obstacle.x} - #{obstacle.y}"
            @physics_player.body.round_y!(32)
          end
          @physics_player.reset_jump!
          @physics_player.body.apply_surface_friction(obstacle)
        when :top
          @physics_player.body.reset_speed_y if @physics_player.body.speed_y < 0
        when :right
          @physics_player.body.reset_speed_x if @physics_player.body.speed_x < 0
          p "collide right to #{obstacle.x} - #{obstacle.y}"
        when :left
          @physics_player.body.reset_speed_x if @physics_player.body.speed_x > 0
          p "collide left to #{obstacle.x} - #{obstacle.y}"
        end
      else
        p "didn't collide"
        @physics_player.body.apply_air_friction
      end
    end
  end
end
