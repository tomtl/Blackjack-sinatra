require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_STAYS_ON_AMOUNT = 17

helpers do
  def calculate_total(cards) # cards is [ ['H', '9'], ['C', 'K'] ... ]
    arr = cards.map{ |element| element[1] }
    
    total = 0
    arr.each do |rank|
      if rank == "A"
        total += 11
      else
        total += rank.to_i == 0 ? 10 : rank.to_i
      end
    end
    
    # Correct for aces
    arr.select{ |element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end
    
    total
  end
  
  def card_image(card) # ["H", "4"]
    suit = case card[0]
      when "H" then "hearts"
      when "D" then "diamonds"
      when "C" then "clubs"
      when "S" then "spades"
    end
    
    value = card[1]
    if ["J", "Q", "K", "A"].include?(value)
      value = case card[1]
        when "J" then "jack"
        when "Q" then "queen"
        when "K" then "king"
        when "A" then "ace"
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
  
  def winner!(msg)
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    @show_hit_or_stay_buttons = false
    @play_again = true
  end
  
  def loser!(msg)
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
    @show_hit_or_stay_buttons = false
    @play_again = true
  end
  
  def tie!(msg)
    @success = "<strong>It's a tie!</strong> #{msg}"
    @show_hit_or_stay_buttons = false
    @play_again = true
  end
end

before do
  @show_hit_or_stay_buttons = true  
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:new_player)
  end
  
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]
  
  # Create a deck and put it in session
  suits = ['C', 'D', 'S', 'H']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! # [ ['H', '9'], ['C', 'K'] ... ]

  # Deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack.")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("Looks like #{session[:player_name]} has busted on #{player_total}.")
  end
  
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_cards])
  
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer has busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_STAYS_ON_AMOUNT
    # dealer stays
    redirect '/game/compare'
  else
    # dealer hits
    @show_dealer_hit_button = true
  end
  
  erb :game
end
post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  
  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!"Both #{session[:player_name]} and the dealer stayed at #{player_total}."
  end
  
  erb :game
end

get '/game_over' do
  erb :game_over
end