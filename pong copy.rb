require "bundler/setup"
require "hasu"

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

  def draw
    case @state
    when :menu
      draw_menu
    when :instructions
      draw_instructions
    else
      @ball.draw(self)
      @font.draw(@left_score, 50, 50, 0)
      @font.draw(@right_score, WIDTH - 100, 50, 0)
      @left_paddle.draw(self)
      @right_paddle.draw(self)
    end
  end

  def draw_menu
    @logo.draw(WIDTH / 4 - @logo.width * @logo_scale / 2, 100, 0, @logo_scale, @logo_scale) # Desenhar o logo no menu
    @small_font.draw_text("1. Jogar contra I.A", WIDTH / 4 - 200, 400, 0, 1, 1, menu_option_color(1))
    @small_font.draw_text("2. Jogar contra Amigo", WIDTH / 4 - 200, 500, 0, 1, 1, menu_option_color(2))
    @small_font.draw_text("3. Como jogar", WIDTH / 4 - 200, 600, 0, 1, 1, menu_option_color(3))
    draw_ranking
  end

  def draw_ranking
    @font.draw_text("Ranking", 3 * WIDTH / 4 - 100, 200, 0)
    @small_font.draw_text("1. Jogador 1 - 10", 3 * WIDTH / 4 - 100, 300, 0) # Placeholder for rankings
    @small_font.draw_text("2. Jogador 2 - 8", 3 * WIDTH / 4 - 100, 350, 0)  # Placeholder for rankings
  end

  def draw_instructions
    @font.draw_text("Como jogar", WIDTH / 2 - 150, 200, 0)
    @small_font.draw_text("Use as teclas W e S para mover a raquete esquerda", WIDTH / 4, 400, 0)
    @small_font.draw_text("Use as setas para mover a raquete direita", WIDTH / 4, 450, 0)
    @small_font.draw_text("Pressione Esc para voltar ao menu", WIDTH / 4, 500, 0)
  end

  def update
    if @state == :menu
      handle_menu_input
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
        @ball = Ball.new
      end
      if @ball.off_right?
        @left_score += 1
        @ball = Ball.new
      end
    end
  end

  def menu_option_color(option)
    mouse_x.between?(WIDTH / 4 - 200, WIDTH / 4 + 200) && mouse_y.between?(option_y(option), option_y(option) + 30) ? Gosu::Color::YELLOW : Gosu::Color::WHITE
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
        @state = :game
        reset
      elsif mouse_over_option?(3)
        @state = :instructions
      end
    end
  end

  def mouse_over_option?(option)
    mouse_x.between?(WIDTH / 4 - 200, WIDTH / 4 + 200) && mouse_y.between?(option_y(option), option_y(option) + 30)
  end

  def button_down(button)
    case @state
    when :menu
      handle_menu_input
    when :game
      case button
      when Gosu::KbEscape
        @state = :menu
      end
    when :instructions
      @state = :menu if button == Gosu::KbEscape
    end
  end
end

Pong.run
