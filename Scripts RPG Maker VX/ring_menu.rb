#==============================================================================
# ** Ring Menu
#------------------------------------------------------------------------------
#  This is a simple ring menu.
#          - Core classes are in module Zangther including
#                  - Scene_RingMenu
#                  - Spriteset_Iconring
#                  - Sprite_Icon
#          - Configuration is in the module Zangther::RingMenu::Config
#          - You can change fade_in and fade_out methods, they are into Zangther::RingMenu::Config::Fade
#          - Some edits to Scene_Map, Scene_Item, Scene_File and Scene_End are made at the end of the file in 
#               order to make them compatible with this ring menu. 
#                     (#call_menu for Scene_Map and #return_scene for the others)
#------------------------------------------------------------------------------
# Version : 1.2 by Zangther
#     If any questions, contact me at zangther@gmail.com
#-----------------------------------------------------------------------------
# Changelog :
#     v 1.2 : Add actor selection for Scene_Skill, Scene_Equip and Scene_Status
#     v 1.1 : Cleaning
#     v 1.0 : Base script
#-----------------------------------------------------------------------------
#       Special thanks to Molok, Raho, Nuki, S4suk3 and Grim from Funkywork
#         for advises and constant support ! [ http://funkywork.jeun.fr ]
#==============================================================================
module Zangther
  module RingMenu
    module Config
      # Menus's commands
      MENU_COMMAND = [
      # :name => "Name", :icon => ID, :action => lambda { new scene }
        {:name => "Items", :icon => 144, :action => lambda { Scene_Item.new }},
        {:name => "Skills", :icon => 145, :action => lambda { Scene_HeroMenu.new(Scene_Skill, 1) }},
        {:name => "Equip", :icon => 32, :action => lambda { Scene_HeroMenu.new(Scene_Equip, 2) }},
        {:name => "Status", :icon => 85, :action => lambda { Scene_HeroMenu.new(Scene_Status, 3) }},
        {:name => "File", :icon => 133, :action => lambda { Scene_File.new(true, false, false) }},
        {:name => "Exit", :icon => 137, :action => lambda { Scene_End.new }}
      ]
      
      # Angle de base
      START_ANGLE = 1.5 * Math::PI
      # Distance
      DISTANCE = 50
    end
    #==============================================================================
    # ** Fade
    #------------------------------------------------------------------------------
    #  Contains methods about fade in and fade out for ring menu.
    #==============================================================================
    module Fade
      #--------------------------------------------------------------------------
      # * Fade in
      #--------------------------------------------------------------------------
      def fade_in(distance)
        distance = distance.to_i
        total_spin
        dist_step = (distance - @distance) / (6.28 / @step)
        opa_step = 255 / (6.28 / @step)
        recede(distance,  dist_step)
        change_opacity(255, opa_step)
        @state = :openning
      end
      #--------------------------------------------------------------------------
      # * Fade out
      #--------------------------------------------------------------------------
      def fade_out(distance)
        distance = distance.to_i
        total_spin
        dist_step = (distance - @distance) / (6.28 / @step)
        opa_step = 255 / (6.28 / @step)
        approach(distance,  dist_step)
        change_opacity(0, -opa_step)
        @state = :closing
      end
    end
    #==============================================================================
    # ** Icon
    #------------------------------------------------------------------------------
    #  Add sevreal methods related to icons
    #==============================================================================
    module Icon
      #--------------------------------------------------------------------------
      # * Place the sprite
      #--------------------------------------------------------------------------
      def place(x, y, distance, angle)
        # Force values to numeric
        distance = distance.to_i
        angle = angle.to_f
        # Polar coordinations calculation
        self.x = x.to_i + (Math.cos(angle)*distance)
        self.y = y.to_i + (Math.sin(angle)*distance)
        update
      end
    end
  end
  #==============================================================================
  # ** Scene_RingMenu
  #------------------------------------------------------------------------------
  #  This scene used to be an adventurer like you, but then it took an arrow in the knee.
  #==============================================================================
  class Scene_RingMenu < Scene_Base
    #--------------------------------------------------------------------------
    # * Initialize
    #--------------------------------------------------------------------------
    def initialize(index = 0)
      @index = index.to_i
    end
    #--------------------------------------------------------------------------
    # * Start processing
    #--------------------------------------------------------------------------
    def start
      super
      create_menu_background
      create_command_ring
      create_command_name
    end
    #--------------------------------------------------------------------------
    # * Termination Processing
    #--------------------------------------------------------------------------
    def terminate
      super
      dispose_menu_background
      dispose_command_name
    end
    #--------------------------------------------------------------------------
    # * Frame Update
    #--------------------------------------------------------------------------
    def update
      super
      if @command_ring.closed?
        @command_ring.dispose
        change_scene
      else
        @command_ring.update
        update_command_name
        update_command_selection unless @command_ring.closing?
      end
      update_menu_background
    end
    
    private
    #--------------------------------------------------------------------------
    # * Create Command Ring
    #--------------------------------------------------------------------------
    def create_command_ring
      icons = Array.new
      RingMenu::Config::MENU_COMMAND.each do |command|
        icons.push(icon = Sprite_Icon.new)
        icon.bitmap = Cache.system("Iconset")
        index = command[:icon]
        x = index % 16 * 24
        y = (index / 16).truncate * 24
        icon.src_rect = Rect.new(x,y,24,24)
      end
      x = $game_player.screen_x - 28
      y = $game_player.screen_y - 44
      distance = RingMenu::Config::DISTANCE
      angle = RingMenu::Config::START_ANGLE
      @command_ring = Spriteset_Iconring.new(x, y, distance, 10, angle, icons, @index)
    end
    #--------------------------------------------------------------------------
    # * Create Command Text
    #--------------------------------------------------------------------------
    def create_command_name
      @command_name = Sprite.new
      distance = RingMenu::Config::DISTANCE
      width = distance * 2
      @command_name.bitmap = Bitmap.new(width, 24)
      @command_name.x = $game_player.screen_x  - distance
      @command_name.y = $game_player.screen_y + distance
    end
    #--------------------------------------------------------------------------
    # * Update Command Selection
    #--------------------------------------------------------------------------
    def update_command_selection
      if Input.trigger?(Input::B)
        Sound.play_cancel
        prepare_scene {return_scene}
      elsif Input.trigger?(Input::LEFT)
        @command_ring.spin_left
      elsif Input.trigger?(Input::RIGHT)
        @command_ring.spin_right
      elsif Input.trigger?(Input::C)
        Sound.play_decision
        prepare_scene {next_scene}
      end
    end
    #--------------------------------------------------------------------------
    # * Update Command Text
    #--------------------------------------------------------------------------
    def update_command_name
      rect = @command_name.src_rect
      command = RingMenu::Config::MENU_COMMAND[@command_ring.index]
      bitmap = @command_name.bitmap
      bitmap.clear
      bitmap.draw_text(rect, command[:name], 1)
    end
    #--------------------------------------------------------------------------
    # * Dispose Command Text
    #--------------------------------------------------------------------------
    def dispose_command_name
      @command_name.dispose
    end
    #--------------------------------------------------------------------------
    # * Prepare transition for new scene
    #--------------------------------------------------------------------------
    def prepare_scene
      @scene = yield.call
      @command_ring.pre_terminate
    end  
    #--------------------------------------------------------------------------
    # * Execute transition to new scene
    #--------------------------------------------------------------------------
    def change_scene
      $scene = @scene
    end
    #--------------------------------------------------------------------------
    # * Load the return scene
    #--------------------------------------------------------------------------
    def return_scene
      lambda {Scene_Map.new}
    end
    #--------------------------------------------------------------------------
    # * Load the next scene
    #--------------------------------------------------------------------------
    def next_scene
      RingMenu::Config::MENU_COMMAND[@command_ring.index][:action]
    end
  end
  #==============================================================================
  # ** Scene_HeroMenu
  #------------------------------------------------------------------------------
  #  Dance like it hurts, Love like you need money, Work when people are watching.
  #==============================================================================
  class Scene_HeroMenu < Scene_RingMenu
    #--------------------------------------------------------------------------
    # * Initialize
    #--------------------------------------------------------------------------
    def initialize(scene, return_index = 0)
      raise "scene must be a Class object !" unless scene.is_a?(Class)
      @next_scene = scene
      @return_index = return_index.to_i
    end
    
    private
    #--------------------------------------------------------------------------
    # * Create Command Ring
    #--------------------------------------------------------------------------
    def create_command_ring
      icons = $game_party.members.map do |actor|
        char = Game_Character.new
        char.set_graphic(actor.character_name,actor.character_index)
        Sprite_Character_Icon.new(char)
      end
      x = $game_player.screen_x - 16
      y = $game_player.screen_y - 16
      distance = RingMenu::Config::DISTANCE
      angle = RingMenu::Config::START_ANGLE
      @command_ring = Spriteset_Iconring.new(x, y, distance, 10, angle, icons)
    end
    #--------------------------------------------------------------------------
    # * Create Command Text
    #--------------------------------------------------------------------------
    def create_command_name
      @command_name = Sprite.new
      distance = RingMenu::Config::DISTANCE
      width = distance * 2
      @command_name.bitmap = Bitmap.new(width, 24)
      @command_name.x = $game_player.screen_x  - distance
      @command_name.y = $game_player.screen_y + distance
    end
    #--------------------------------------------------------------------------
    # * Update Command Text
    #--------------------------------------------------------------------------
    def update_command_name
      rect = @command_name.src_rect
      hero = $game_party.members[@command_ring.index]
      bitmap = @command_name.bitmap
      bitmap.clear
      bitmap.draw_text(rect, hero.name, 1)
    end
    #--------------------------------------------------------------------------
    # * Load the return scene
    #--------------------------------------------------------------------------
    def return_scene
      lambda {Scene_RingMenu.new(@return_index)}
    end
    #--------------------------------------------------------------------------
    # * Load the next scene
    #--------------------------------------------------------------------------
    def next_scene
      lambda {@next_scene.new(@command_ring.index)}
    end
  end
  #==============================================================================
  # ** Sprite_Icon
  #------------------------------------------------------------------------------
  #  Just inherit from Sprite and Icon
  #==============================================================================
  class Sprite_Icon < Sprite
    include RingMenu::Icon
  end
  #==============================================================================
  # ** Sprite_Character_Icon
  #------------------------------------------------------------------------------
  #  Just inherit from Sprite_Character and Icon, changes update to prevent placement issues
  #==============================================================================
  class Sprite_Character_Icon < Sprite_Icon
    #--------------------------------------------------------------------------
    # * Object Initialization
    #     viewport  : viewport
    #     character : character (Game_Character)
    #--------------------------------------------------------------------------
    def initialize(character = nil)
      super(nil)
      @character = character
      update
    end
    #--------------------------------------------------------------------------
    # * Frame Update
    #--------------------------------------------------------------------------
    def update
      super
      update_bitmap
      update_src_rect
      self.z = @character.screen_z
    end
    #--------------------------------------------------------------------------
    # * Get tile set image that includes the designated tile
    #     tile_id : Tile ID
    #--------------------------------------------------------------------------
    def tileset_bitmap(tile_id)
      set_number = tile_id / 256
      return Cache.system("TileB") if set_number == 0
      return Cache.system("TileC") if set_number == 1
      return Cache.system("TileD") if set_number == 2
      return Cache.system("TileE") if set_number == 3
      return nil
    end
    #--------------------------------------------------------------------------
    # * Update Transfer Origin Bitmap
    #--------------------------------------------------------------------------
    def update_bitmap
      if @tile_id != @character.tile_id or
         @character_name != @character.character_name or
         @character_index != @character.character_index
        @tile_id = @character.tile_id
        @character_name = @character.character_name
        @character_index = @character.character_index
        if @tile_id > 0
          sx = (@tile_id / 128 % 2 * 8 + @tile_id % 8) * 32;
          sy = @tile_id % 256 / 8 % 16 * 32;
          self.bitmap = tileset_bitmap(@tile_id)
          self.src_rect.set(sx, sy, 32, 32)
          self.ox = 16
          self.oy = 32
        else
          self.bitmap = Cache.character(@character_name)
          sign = @character_name[/^[\!\$]./]
          if sign != nil and sign.include?('$')
            @cw = bitmap.width / 3
            @ch = bitmap.height / 4
          else
            @cw = bitmap.width / 12
            @ch = bitmap.height / 8
          end
          self.ox = @cw / 2
          self.oy = @ch
        end
      end
    end
    #--------------------------------------------------------------------------
    # * Update Transfer Origin Rectangle
    #--------------------------------------------------------------------------
    def update_src_rect
      if @tile_id == 0
        index = @character.character_index
        pattern = @character.pattern < 3 ? @character.pattern : 1
        sx = (index % 4 * 3 + pattern) * @cw
        sy = (index / 4 * 4 + (@character.direction - 2) / 2) * @ch
        self.src_rect.set(sx, sy, @cw, @ch)
      end
    end
  end
  #==============================================================================
  # ** Spriteset_Iconring
  #------------------------------------------------------------------------------
  #  This class manages Sprite_Icon and make then spin around a point.
  #==============================================================================
  class Spriteset_Iconring
    #--------------------------------------------------------------------------
    # * Module inclusions
    #--------------------------------------------------------------------------
    include RingMenu::Fade
    #--------------------------------------------------------------------------
    # * Public Instance Variables
    #--------------------------------------------------------------------------
    attr_reader :x
    attr_reader :y
    attr_reader :distance
    attr_reader :angle
    attr_reader :direction
    attr_reader :actual_direction
    attr_reader :index
    #--------------------------------------------------------------------------
    # * Public Instance Variables
    #--------------------------------------------------------------------------
    PI_2 = 6.28
    #--------------------------------------------------------------------------
    # * Constructor
    #--------------------------------------------------------------------------
    def initialize(x, y, distance, speed, angle, sprites, index = 0, direction=:trigo)
      # Argument test
      sprites = Array(sprites)
      unless sprites.all? { |sp| (sp.is_a?(RingMenu::Icon)) }
        raise(ArgumentError, "sprite isn't an array of Sprite_Icons") 
      end
      # Adjust numeric arguments
      @x = x.to_i + 16
      @y = y.to_i + 16
      @distance = @future_distance = 0
      @speed = speed.to_i
      @angle = (angle.to_f - (index * (PI_2 / sprites.size))).modulo PI_2
      # Settings
      @shift = {:trigo => 0, :antitrigo => 0}
      @direction = @actual_direction = direction
      @index = index.to_i
      @opacity = @future_opacity = 0
      @icons = sprites
      @state = :closed
      self.step = :default
      fade_in(distance)
      update(true)
    end
    #--------------------------------------------------------------------------
    # * Update
    # need_refresh : force refresh
    #--------------------------------------------------------------------------
    def update(need_refresh=false)
      return unless @icons
      if moving?
        if spinning?
          reverse_direction if need_reverse?
          update_angle
        end
        update_distance
        need_refresh = true
      end
      update_opacity
      update_state
      refresh if need_refresh
    end
    #--------------------------------------------------------------------------
    # * Dispose
    #--------------------------------------------------------------------------
    def pre_terminate
      fade_out(0)
    end
    #--------------------------------------------------------------------------
    # * Dispose
    #--------------------------------------------------------------------------
    def dispose
      @icons.each {|icon| icon.dispose}
    end
    #--------------------------------------------------------------------------
    # * Refresh
    #--------------------------------------------------------------------------
    def refresh
      @icons.size.times do |i|
        icon = @icons[i]
        angle = @angle + ((PI_2/(@icons.size))*i)
        icon.place(@x,@y,@distance,angle)
        icon.opacity = @opacity
        icon.update
      end
    end
    #--------------------------------------------------------------------------
    # * Spin
    #--------------------------------------------------------------------------
    def spin
      unless spinning?
        number_of_icons = @icons.size
        @shift[@direction] += PI_2/number_of_icons
        if @direction == :trigo
          @index += 1
        else
          @index -= 1
        end
        @index = @index.modulo number_of_icons
      end
    end
    #--------------------------------------------------------------------------
    # * Change direction
    #     direction :  :trigo, :antitrigo, :+, :-, :positif, :negatif
    #--------------------------------------------------------------------------
    def change_direction(direction)
      case direction
      when :trigo, :+, :positif
        @direction = :trigo
      when :antitrigo, :-, :negatif
        @direction = :antitrigo
      end
    end
    #--------------------------------------------------------------------------
    # * Change center
    #   x,y : Entiers
    #--------------------------------------------------------------------------
    def changer_centre(x, y)
      @x = x.to_i
      @y = y.to_i
    end
    #--------------------------------------------------------------------------
    # * Définir distance
    #--------------------------------------------------------------------------
    def angle=(angle)
      if angle > PI_2 || angle < 0
        angle = 0
      end
      @angle = angle.to_f
    end
    #--------------------------------------------------------------------------
    # * Maj step
    #--------------------------------------------------------------------------
    def step=(step=1)
      if step == :default
        number_of_icons = @icons.size
        @step = PI_2 / (number_of_icons*100) * @speed 
      else
        @step = step.to_f * @speed
      end
    end
    #--------------------------------------------------------------------------
    # * Spin right
    #--------------------------------------------------------------------------
    def spin_right
      change_direction(:+)
      spin
    end
    #--------------------------------------------------------------------------
    # * Spin right
    #--------------------------------------------------------------------------
    def spin_left
      change_direction(:-)
      spin
    end
    #--------------------------------------------------------------------------
    # * Move away from center
    #--------------------------------------------------------------------------
    def recede(distance, step = 1)
      @future_distance = distance.to_i
      @distance_step = step.abs
    end
    #--------------------------------------------------------------------------
    # * Move back to center
    #--------------------------------------------------------------------------
    def approach(distance, step = 1)
      @future_distance = distance.to_i
      @distance_step = - step.abs
    end
    #--------------------------------------------------------------------------
    # * Changes opacity
    #--------------------------------------------------------------------------
    def change_opacity(opacity, step = 1)
      if opacity > 255
        @future_opacity = 255
      elsif opacity < 0
        @future_opacity = 0
      else
        @future_opacity = opacity.to_i
      end
      @opacity_step = step.to_i
    end
    #--------------------------------------------------------------------------
    # * Is closed ?
    #--------------------------------------------------------------------------
    def closed?
      @state == :closed
    end
    #--------------------------------------------------------------------------
    # * Is opened ?
    #--------------------------------------------------------------------------
    def opened?
      @state == :opened
    end
    #--------------------------------------------------------------------------
    # * Is closing ?
    #--------------------------------------------------------------------------
    def closing?
      @state == :closing
    end
    #--------------------------------------------------------------------------
    # * Is openning ?
    #--------------------------------------------------------------------------
    def openning?
      @state == :openning
    end

    private
    #--------------------------------------------------------------------------
    # * Updates angle positionning
    #--------------------------------------------------------------------------
    def update_angle
      direction = @actual_direction
      shift = @shift[direction]
      step = @step > shift ? shift : @step
      step *= -1 if direction == :trigo
      temp = @angle + step
      if direction == :trigo && temp < 0
        temp += PI_2
      elsif direction == :antitrigo && temp > PI_2
        temp -= PI_2
      end
      @angle = temp
      @shift[direction] = shift-@step
      @shift[direction] = 0 if @shift[direction] < 0
    end
    #--------------------------------------------------------------------------
    # * Updates distance positionning
    #--------------------------------------------------------------------------
    def update_distance
      return if @future_distance == @distance
      temp = @distance + @distance_step
      # Checks if @future_distance is between temp and @distance
      # If so, that's mean that @distance_step is bigger than the gap between @distance & @future_distance
      if (@distance..temp).include?(@future_distance) || (temp..@distance).include?(@future_distance)
        @distance = @future_distance
      else
        @distance += @distance_step
      end
    end
    #--------------------------------------------------------------------------
    # * Updates opacity
    #--------------------------------------------------------------------------
    def update_opacity
      shift = @future_opacity - @opacity
      return if shift == 0
      @opacity += @opacity_step
      if shift > 0
        @opacity = @future_opacity if @opacity > @future_opacity
      else
        @opacity = @future_opacity if @opacity < @future_opacity
      end
    end
    #--------------------------------------------------------------------------
    # * Updates state
    #--------------------------------------------------------------------------
    def update_state
      unless spinning?
        if @state == :closing
          @state = :closed
        elsif @state == :openning
          @state = :opened
        end
      end
    end
    #--------------------------------------------------------------------------
    # * Reverse the direction 
    #--------------------------------------------------------------------------
    def reverse_direction
      @actual_direction = (@actual_direction == :trigo ? :antitrigo : :trigo)
    end
    #--------------------------------------------------------------------------
    # * Need revesing direction ?
    #--------------------------------------------------------------------------
    def need_reverse?
      @shift[@actual_direction] <= 0
    end
    #--------------------------------------------------------------------------
    # * Spinning
    #--------------------------------------------------------------------------
    def spinning?
      @shift.any? {|key,val| val > 0}
    end
    #--------------------------------------------------------------------------
    # * Moving ?
    #--------------------------------------------------------------------------
    def moving?
      spinning? || (@future_distance != @distance)
    end
    #--------------------------------------------------------------------------
    # * Make one complete spin
    #--------------------------------------------------------------------------
    def total_spin
        @shift[@direction] += PI_2 unless spinning?
    end
  end 
end 
#==============================================================================
# ** Scene_Map
#------------------------------------------------------------------------------
#  Edit #call_menu
#==============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Switch to Menu Screen
  #--------------------------------------------------------------------------
  def call_menu
    if $game_temp.menu_beep
      Sound.play_decision
      $game_temp.menu_beep = false
    end
    $game_temp.next_scene = nil
    $scene = Zangther::Scene_RingMenu.new
  end
end
#==============================================================================
# ** Scenes
#------------------------------------------------------------------------------
#  Edits #return_scene
#==============================================================================
class Scene_Item < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(0)
  end
end
  
class Scene_Skill < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(1)
  end
end

class Scene_Equip < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(2)
  end
end

class Scene_Status < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(3)
  end
end

class Scene_File < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    if @from_title
      $scene = Scene_Title.new
    elsif @from_event
      $scene = Scene_Map.new
    else
      $scene = Zangther::Scene_RingMenu.new(4)
    end
  end
end

class Scene_End < Scene_Base
  #--------------------------------------------------------------------------
  # * Return to Original Screen
  #--------------------------------------------------------------------------
  def return_scene
    $scene = Zangther::Scene_RingMenu.new(5)
  end
end
