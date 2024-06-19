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
  
    # Desenhar os nomes dos jogadores ao lado do placar apenas no modo contra amigo
    if !@ai
      if @player1_name
        @small_font.draw_text(@player1_name, WIDTH / 2 - score_width - 10 - @small_font.text_width(@player1_name) - 20, 120, 0, 1, 1, Gosu::Color::RED)
      end
    
      if @player2_name
        @small_font.draw_text(@player2_name, WIDTH / 2 + 10 + score_width + 20, 120, 0, 1, 1, Gosu::Color::BLUE)
      end
    end
  
    @left_paddle.draw(self)
    @right_paddle.draw(self)
  end
  
  
  

  def draw_menu
    @logo.draw(WIDTH / 3 - @logo.width * @logo_scale / 2, 160, 0, @logo_scale, @logo_scale) # Desenhar o logo no menu
    @small_font.draw_text("1. Jogar contra I.A", WIDTH / 2 - 450, 400, 0, 1, 1, menu_option_color(1))
    @small_font.draw_text("2. Jogar contra Amigo", WIDTH / 2 - 450, 500, 0, 1, 1, menu_option_color(2))
    @small_font.draw_text("3. Como jogar", WIDTH / 2 - 450, 600, 0, 1, 1, menu_option_color(3))
    draw_ranking
  end

  def draw_ranking
    # Título do ranking
    title_text = "Ranking - TOP 5 WINS"
    title_width = @font.text_width(title_text)
    title_x = WIDTH - title_width - 359.9  # Colocando 20 pixels de margem à direita
    @font.draw_text(title_text, title_x, 200, 0, 1.0, 1.0, Gosu::Color::RED)
    
    # Limitar a exibição aos top 5 jogadores
    top_players = @ranking.take(5)
    
    text_width = top_players.map { |entry| @small_font.text_width("#{entry[:name]} → #{entry[:wins]} vitórias") }.max
    line_height = @small_font.height
    text_height = line_height * top_players.size + 20
    
    box_x = (WIDTH - text_width) / 1.1 - 430 
    box_y = 300 - 20
    box_width = 10 + text_width + 200
    box_height = 10 + text_height + 20
    
    if box_x < 0
      box_x = 0
    end
    
    draw_dotted_line(box_x, box_y, box_x + box_width, box_y)
    draw_dotted_line(box_x, box_y, box_x, box_y + box_height)
    draw_dotted_line(box_x + box_width, box_y, box_x + box_width, box_y + box_height)
    draw_dotted_line(box_x, box_y + box_height, box_x + box_width, box_y + box_height)
    
    # Coordenadas para o texto dos jogadores
    players_x = box_x
    players_y = 300
    
    # Desenhar os jogadores dentro da caixa
    top_players.each_with_index do |entry, index|
      @small_font.draw_text("   #{index + 1}. #{entry[:name]} → #{entry[:wins]} vitórias", players_x, players_y + index * (line_height + 10), 0, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end
  

  def draw_player_names
    @small_font.draw_text("Digite o nome do Jogador 1:", WIDTH / 2 - 200, 400, 0)
    @player1_name_field.draw
    @small_font.draw_text("Digite o nome do Jogador 2:", WIDTH / 2 - 200, 500, 0)
    @player2_name_field.draw
  end
  
  def draw_instructions
   
    title_text = "Como jogar ?"
    title_x = (WIDTH - @font.text_width(title_text)) / 2
    @font.draw_text(title_text, title_x, 200, 0, 1.0, 1.0, Gosu::Color::RED)
  
    # Texto das instruções
    instructions = [
      "• Use as teclas W e S para mover a raquete esquerda",
      "• Use as setas para mover a raquete direita",
      "• Pressione Esc ou no botão Voltar para voltar ao menu"
    ]
  
    # Medir a largura e altura do texto
    text_width = instructions.map { |text| @small_font.text_width(text) }.max
    line_height = @small_font.height
    text_height = line_height * instructions.size + 20
  
    # Coordenadas da caixa ao redor do texto
    box_x = (WIDTH - text_width) / 2 - 20
    box_y = 380 - 20
    box_width = 10 + text_width + 40
    box_height = 15 + text_height + 20
  
    # Desenhar as bordas da caixa de texto como pontilhadas
    draw_dotted_line(box_x, box_y, box_x + box_width, box_y)
    draw_dotted_line(box_x, box_y, box_x, box_y + box_height)
    draw_dotted_line(box_x + box_width, box_y, box_x + box_width, box_y + box_height)
    draw_dotted_line(box_x, box_y + box_height, box_x + box_width, box_y + box_height)
  
    # Coordenadas centralizadas para o texto
    instructions_x = (WIDTH - text_width) / 2
    instructions_y = 380
  
    # Desenhar as instruções dentro da caixa
    instructions.each_with_index do |text, index|
      @small_font.draw_text(text, instructions_x, instructions_y + index * (line_height + 10), 0, 1.0, 1.0, Gosu::Color::WHITE)
    end
  
  
  return_button_text = "Voltar"
  return_button_text_width = @small_font.text_width(return_button_text)
  return_button_x = WIDTH / 2 - return_button_text_width / 2
  return_button_y = HEIGHT - 100
  return_button_width = return_button_text_width + 20
  return_button_height = @small_font.height + 10

  # Determinar a cor do botão baseado na interação do mouse
  if mouse_x.between?(return_button_x, return_button_x + return_button_width) &&
     mouse_y.between?(return_button_y, return_button_y + return_button_height)
    button_color = Gosu::Color::GRAY
  else
    button_color = Gosu::Color::BLACK
  end

  # Desenhar o retângulo do botão
  Gosu.draw_rect(return_button_x, return_button_y, return_button_width, return_button_height, button_color, 0)

  # Desenhar o texto do botão
  @small_font.draw_text(return_button_text, return_button_x + 10, return_button_y + 5, 0, 1.0, 1.0, Gosu::Color::RED)

  # Verificar se o jogador clicou no botão de voltar
  if button_down?(Gosu::MsLeft) &&
     mouse_x.between?(return_button_x, return_button_x + return_button_width) &&
     mouse_y.between?(return_button_y, return_button_y + return_button_height)
    @state = :menu
  end
end
  
  
  def draw_dotted_line(x1, y1, x2, y2, dot_length = 5, space_length = 5)
    dx = x2 - x1
    dy = y2 - y1
    distance = Math.sqrt(dx * dx + dy * dy)
    dx /= distance
    dy /= distance
  
    current_length = 0
    draw = true
  
    while current_length < distance
      if draw
        x_start = x1 + dx * current_length
        y_start = y1 + dy * current_length
        x_end = x1 + dx * [current_length + dot_length, distance].min
        y_end = y1 + dy * [current_length + dot_length, distance].min
  
        Gosu.draw_line(x_start, y_start, Gosu::Color::WHITE, x_end, y_end, Gosu::Color::WHITE, 0)
      end
  
      current_length += draw ? dot_length : space_length
      draw = !draw
    end
  end
  
  def draw_dotted_line(x1, y1, x2, y2, dot_length = 5, space_length = 5)
    dx = x2 - x1
    dy = y2 - y1
    distance = Math.sqrt(dx * dx + dy * dy)
    dx /= distance
    dy /= distance
  
    current_length = 0
    draw = true
  
    while current_length < distance
      if draw
        x_start = x1 + dx * current_length
        y_start = y1 + dy * current_length
        x_end = x1 + dx * [current_length + dot_length, distance].min
        y_end = y1 + dy * [current_length + dot_length, distance].min
  
        Gosu.draw_line(x_start, y_start, Gosu::Color::WHITE, x_end, y_end, Gosu::Color::WHITE, 0)
      end
  
      current_length += draw ? dot_length : space_length
      draw = !draw
    end
  end

  def draw_victory
    if @ai
      winner_text = @winner == :left ? "A máquina venceu!" : "Você venceu!"
    else
      winner_name = @winner == :left ? @player1_name : @player2_name
      winner_text = "#{winner_name} venceu a partida!"
    end
    
    # Calculando a posição x para centralizar o texto de vitória
    winner_text_width = @font.text_width(winner_text)
    winner_text_x = (WIDTH - winner_text_width) / 2
    
    # Desenhar o texto de vitória centralizado
    @font.draw_text(winner_text, winner_text_x, HEIGHT / 2 - 100, 0, 1, 1, Gosu::Color::GREEN)
    
    # Calculando a posição x para centralizar o texto "Pressione Enter para voltar ao menu"
    return_to_menu_text = "Pressione Enter para voltar ao menu"
    return_to_menu_text_width = @small_font.text_width(return_to_menu_text)
    return_to_menu_text_x = (WIDTH - return_to_menu_text_width) / 2
    
    # Desenhar o texto "Pressione Enter para voltar ao menu" centralizado em relação ao texto de vitória
    @small_font.draw_text(return_to_menu_text, return_to_menu_text_x, HEIGHT / 2, 0, 1, 1, Gosu::Color::WHITE)
  end
  
  
  def update
    case @state
    when :menu
      handle_menu_input
    when :player_names
      # Não há lógica de atualização necessária para a entrada de nomes dos jogadores
    when :victory
      handle_victory_input
    when :game
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
      if @ai
        puts "A máquina venceu!"
      else
        puts "#{@player1_name} venceu!"
        update_ranking(@player1_name)  # Atualiza ranking apenas no modo contra amigo
      end
    elsif @right_score >= 5
      @winner = :right
      @state = :victory
      if @ai
        puts "Você venceu!"
        # Não atualiza ranking no modo contra máquina
      else
        puts "#{@player2_name} venceu!"
        update_ranking(@player2_name)  # Atualiza ranking apenas no modo contra amigo
      end
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
    mouse_x.between?(WIDTH / 2 - 450, WIDTH / 2 + 200) && mouse_y.between?(option_y(option), option_y(option) + 30) ? Gosu::Color::YELLOW : Gosu::Color::WHITE
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
        @player1_name_field = TextField.new(self, WIDTH / 2 - 200, 450)
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
    mouse_x.between?(WIDTH / 2 - 450, WIDTH / 2 + 20) && mouse_y.between?(option_y(option), option_y(option) + 30)
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
  
  
    # Verificar se o jogador clicou no botão de voltar
    if @state == :instructions && button == Gosu::MsLeft
      return_button_text = "Voltar"
      return_button_text_width = @small_font.text_width(return_button_text)
      return_button_x = WIDTH / 2 - return_button_text_width / 2
      return_button_y = HEIGHT - 100
      return_button_width = return_button_text_width + 20
      return_button_height = @small_font.height + 10
  
      if mouse_x.between?(return_button_x - 10, return_button_x + return_button_width - 10) &&
         mouse_y.between?(return_button_y - 5, return_button_y + return_button_height - 5)
        @state = :menu
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
      @window.draw_quad(@x - 5, @y - 5, Gosu::Color::BLACK,
                        @x + width + 5, @y - 5, Gosu::Color::BLACK,
                        @x - 5, @y + height + 5, Gosu::Color::BLACK,
                        @x + width + 5, @y + height + 5, Gosu::Color::BLACK, 0)
      @window.draw_quad(@x, @y, Gosu::Color::WHITE,
                        @x + width, @y, Gosu::Color::WHITE,
                        @x, @y + height, Gosu::Color::WHITE,
                        @x + width, @y + height, Gosu::Color::WHITE, 0)
      @font.draw_text(@text, @x + 5, @y + 5, 0, 1, 1, Gosu::Color::BLACK)
    end
  
    def button_down(id)
      case id
      when Gosu::KbBackspace
        @text.chop!
      when Gosu::KbSpace
        @text += " "
      when Gosu::KbA..Gosu::KbZ, Gosu::Kb0..Gosu::Kb9
        @text += Gosu.button_id_to_char(id).downcase
      end
    end
  
    def text_width
      @font.text_width(@text)
    end
  end
  

Pong.run