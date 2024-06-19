require "bundler/setup"
require "hasu"
require "yaml"

Hasu.load "ball.rb"
Hasu.load "paddle.rb"

class Pong < Hasu::Window
  WIDTH = 1920
  HEIGHT = 1080

  def initialize
    super(WIDTH, HEIGHT, true) # 'true' para tela cheia
    @state = :menu
    @logo = Gosu::Image.new("assets/logo.png") # Carregar a imagem do logo
    @logo_scale = 0.5 # Escala para redimensionar o logo
    @ranking = load_ranking
  end

  def reset
    @ball = Ball.new
    @left_score = 0
    @right_score = 0
    @font = Gosu::Font.new(self, "Arial", 50)
    @small_font = Gosu::Font.new(self, "Arial", 30)
    @left_paddle = Paddle.new(:left, @ai)
    @right_paddle = Paddle.new(:right)
  end

  def load_ranking
    if File.exist?("rankings.yml")
      YAML.load_file("rankings.yml") || []
    else
      []
    end
  end

  def save_ranking
    File.open("rankings.yml", "w") { |file| file.write(@ranking.to_yaml) }
  end

  def draw
    case @state
    when :menu
      draw_menu
    when :player_names
      draw_player_names
    when :instructions
      draw_instructions
    when :victory
      draw_victory
    else
      draw_game
    end
  end

  def draw_game
    @ball.draw(self)
    
    # Placares
    score_text_left = "#{@left_score}"
    score_text_right = "#{@right_score}"
    score_width = @font.text_width(score_text_left)
    @font.draw_text(score_text_left, WIDTH / 2 - score_width - 40, 50, 0)
    @font.draw_text(score_text_right, WIDTH / 2 + 40, 50, 0)
    
    # Linha vertical separadora
    separator_x = WIDTH / 2 - 5
    separator_y1 = 50
    separator_y2 = separator_y1 + @font.height
    draw_line(separator_x, separator_y1, Gosu::Color::WHITE, separator_x, separator_y2, Gosu::Color::WHITE)
  
    @left_paddle.draw(self)
    @right_paddle.draw(self)
  
    # Desenhar os nomes dos jogadores ao lado do placar
    if @player1_name
      @small_font.draw_text(@player1_name, WIDTH / 2 - score_width - 10 - @small_font.text_width(@player1_name) - 20, 120, 0, 1, 1, Gosu::Color::RED)
    end
  
    if @player2_name
      @small_font.draw_text(@player2_name, WIDTH / 2 + 10 + score_width + 20, 120, 0, 1, 1, Gosu::Color::BLUE)
    end
  end
  
  

  def draw_menu
    @logo.draw(WIDTH / 2 - @logo.width * @logo_scale / 2, 100, 0, @logo_scale, @logo_scale) # Desenhar o logo no menu
    @small_font.draw_text("1. Jogar contra I.A", WIDTH / 2 - 200, 400, 0, 1, 1, menu_option_color(1))
    @small_font.draw_text("2. Jogar contra Amigo", WIDTH / 2 - 200, 500, 0, 1, 1, menu_option_color(2))
    @small_font.draw_text("3. Como jogar", WIDTH / 2 - 200, 600, 0, 1, 1, menu_option_color(3))
    draw_ranking
  end

  def draw_ranking
    @font.draw_text("Ranking - TOP 5 WINS", 3 * WIDTH / 4 - 100, 200, 0)
    
    # Limitar a exibição aos top 5 jogadores
    top_players = @ranking.take(5)
    
    top_players.each_with_index do |entry, index|
      @small_font.draw_text("#{index + 1}. #{entry[:name]} → #{entry[:wins]} vitórias", 3 * WIDTH / 4 - 100, 300 + index * 50, 0)
    end
  end
  

  def draw_player_names
    @small_font.draw_text("Digite o nome do Jogador 1:", WIDTH / 2 - 200, 400, 0)
    @player1_name_field.draw
    @small_font.draw_text("Digite o nome do Jogador 2:", WIDTH / 2 - 200, 500, 0)
    @player2_name_field.draw
  end

  def draw_instructions
    @font.draw_text("Como jogar", WIDTH / 2 - 150, 200, 0)
    @small_font.draw_text("Use as teclas W e S para mover a raquete esquerda", WIDTH / 4, 400, 0)
    @small_font.draw_text("Use as setas para mover a raquete direita", WIDTH / 4, 450, 0)
    @small_font.draw_text("Pressione Esc para voltar ao menu", WIDTH / 4, 500, 0)
  end

  def draw_victory
    @font.draw_text("Vitória!", WIDTH / 2 - 100, HEIGHT / 2 - 100, 0, 1, 1, Gosu::Color::GREEN)
    @small_font.draw_text("Pressione Enter para voltar ao menu", WIDTH / 2 - 200, HEIGHT / 2, 0, 1, 1, Gosu::Color::WHITE)
  end

  def update
    if @state == :menu
      handle_menu_input
    elsif @state == :player_names
      # Não há lógica de atualização necessária para a entrada de nomes dos jogadores
    elsif @state == :victory
      handle_victory_input
    else
      @ball.move!
      if @left_paddle.ai?
        @left_paddle.ai_move!(@ball)
      else
        if button_down?(Gosu::KbW)
          @left_paddle.up!
        end
        if button_down?(Gosu::KbS)
          @left_paddle.down!
        end
      end
      if button_down?(Gosu::KbUp)
        @right_paddle.up!
      end
      if button_down?(Gosu::KbDown)
        @right_paddle.down!
      end
      if @ball.intersect?(@left_paddle)
        @ball.bounce_off_paddle!(@left_paddle)
      end
      if @ball.intersect?(@right_paddle)
        @ball.bounce_off_paddle!(@right_paddle)
      end
      if @ball.off_left?
        @right_score += 1
        check_victory
        @ball = Ball.new
      end
      if @ball.off_right?
        @left_score += 1
        check_victory
        @ball = Ball.new
      end
    end
  end

  def check_victory
    if @left_score >= 5
      @winner = :left
      @state = :victory
      update_ranking(@player1_name)
    elsif @right_score >= 5
      @winner = :right
      @state = :victory
      update_ranking(@player2_name)
    end
  end

  def update_ranking(winner_name)
    entry_found = false

    @ranking.each do |entry|
      if entry[:name] == winner_name
        entry[:wins] += 1
        entry_found = true
        break
      end
    end

    unless entry_found
      @ranking << { name: winner_name, wins: 1 }
    end

    save_ranking
  end

  def menu_option_color(option)
    mouse_x.between?(WIDTH / 2 - 200, WIDTH / 2 + 200) && mouse_y.between?(option_y(option), option_y(option) + 30) ? Gosu::Color::YELLOW : Gosu::Color::WHITE
  end

  def option_y(option)
    400 + (option - 1) * 100
  end

  def handle_menu_input
    if button_down?(Gosu::MsLeft)
      if mouse_over_option?(1)
        @ai = true
        @state = :game
        reset
      elsif mouse_over_option?(2)
        @ai = false
        @state = :player_names
        @player1_name_field = TextField.new(self, WIDTH / 2 -         200, 450)
        @player2_name_field = TextField.new(self, WIDTH / 2 - 200, 550)
        @active_field = @player1_name_field
      elsif mouse_over_option?(3)
        @state = :instructions
      end
    end
  end

  def handle_victory_input
    if button_down?(Gosu::KbReturn)
      @state = :menu
    end
  end

  def mouse_over_option?(option)
    mouse_x.between?(WIDTH / 2 - 200, WIDTH / 2 + 200) && mouse_y.between?(option_y(option), option_y(option) + 30)
  end

  def button_down(button)
    case @state
    when :menu
      handle_menu_input
    when :player_names
      if button == Gosu::KbReturn
        if @active_field == @player1_name_field
          @active_field = @player2_name_field
        else
          @player1_name = @player1_name_field.text
          @player2_name = @player2_name_field.text
          @state = :game
          reset
        end
      else
        @active_field.button_down(button)
      end
    when :game
      case button
      when Gosu::KbEscape
        @state = :menu
      end
    when :instructions
      @state = :menu if button == Gosu::KbEscape
    when :victory
      handle_victory_input
    end
  end
end

class TextField
  attr_reader :text

  def initialize(window, x, y)
    @window = window
    @x = x
    @y = y
    @text = ""
    @font = Gosu::Font.new(@window, "Arial", 30)
  end

  def draw
    width = 400
    height = 40
    @window.draw_quad(@x - 5, @y - 5, Gosu::Color::BLACK, @x + width + 5, @y - 5, Gosu::Color::BLACK, @x - 5, @y + height + 5, Gosu::Color::BLACK, @x + width + 5, @y + height + 5, Gosu::Color::BLACK, 0)
    @window.draw_quad(@x, @y, Gosu::Color::WHITE, @x + width, @y, Gosu::Color::WHITE, @x, @y + height, Gosu::Color::WHITE, @x + width, @y + height, Gosu::Color::WHITE, 0)
    @font.draw_text(@text, @x + 5, @y + 5, 0, 1, 1, Gosu::Color::BLACK)
  end

  def button_down(id)
    case id
    when Gosu::KbBackspace
      @text.chop!
    when Gosu::KbSpace
      @text += " "
    when Gosu::KbA..Gosu::KbZ, Gosu::Kb0..Gosu::Kb9
      @text += Gosu.button_id_to_char(id)
    end
  end
end

Pong.run

