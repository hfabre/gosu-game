require "gosu"
require "gosu/animator"
require "gosu/physics"
require "gosu/tilemap"
require_relative "./player"

class Game < Gosu::Window
  def initialize
    super(800, 600)
    self.caption = "Gosu game - #{Gosu::fps()}"

    player_start_x = 64
    player_start_y = 64
    @last_time = Gosu::milliseconds
    @bodies = {
      player: @player,
      obstacles: []
    }
    map_path = "./assets/map.yml"
    @map = Gosu::TileMap.new(self, map_path)
    @camera = Gosu::Camera.new(self, 800, 600, player_start_x, player_start_y, 0, 0, 1)
    @player = Player.new(400, 300, camera: @camera)
    load_body_from_map
  end

  def update
    self.caption = "Gosu game - #{Gosu::fps()}"
    self.close if button_down? Gosu::Button::KbEscape
    update_dt!
    @player.move_left(@dt) if self.button_down? Gosu::Button::KbD
    @player.move_right(@dt) if self.button_down? Gosu::Button::KbA
    @player.update(@dt, @bodies[:obstacles])
  end

  def button_down(id)
    @player.button_down(id, @dt)
  end

  def update_dt!
    @current_time = Gosu::milliseconds
    @dt = @current_time - @last_time
    @last_time = @current_time

    # Fix @dt to make the game fill smoother in case of lag
    @dt = [@dt, 1 / 60.0].min
  end

  def draw
    @map.draw(@camera)
    @camera.draw
    @player.draw
    #@bodies[:obstacles].each(&:draw)
  end

  def load_body_from_map
    @map.board.each_with_index do |line, y|
      line.each_with_index do |cell, x|
        # TODO: arrange tile map so we don't ned this -1 anymore
        if cell != 0 && @map.tiles[cell - 1].collide?
          @bodies[:obstacles] << Gosu::Physics::Body.new(x * 32, y * 32, 32, 32, friction: 0.97)
        end
      end
    end
  end
end

Game.new.show

