require 'facebook/messenger'
require 'httparty'
require 'addressable/uri'
require 'json'
include Facebook::Messenger

# Subcribe bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

UNBOT = "https://westus.api.cognitive.microsoft.com/luis/v2.0/apps/ae7007ff-6b7d-4f73-be7a-cb26e2802087?subscription-key=abc4177072b9452ead3d335addb94ede&timezoneOffset=0&verbose=true&q="
BACK = "https://unbotback.herokuapp.com/buildings/location"
BACK_INFORMATION = "https://unbotback.herokuapp.com/buildings/information"
BACK_ROUTE = "https://unbotback.herokuapp.com/buildings/route"
HOST = "https://unbotback.herokuapp.com"
IDIOMS = {
  general: ["Cuantos años tiene el cyt","historia del viejo","cuando fue fundado enfermeria","apodo del 401","numero del liq", "quien es julio zorra"],
  position: ["Donde queda el viejo","ubicacion de enfermeria","coordenadas de aulas","por donde es el polideportivo","por que lado es el 401"],
  route: ["camino del leon a enfermeria","ruta del liq a facultad de ingenieria","caminar de enfermeria a aulas","lleveme de aulas al cyt"]
}

WITHOUT_ANSWERS = ["ok","genail","bacano"]
LOCALITATION = ["El edificio puede ser encontrado aqui","Mira donde esta el edifico","Espero que esto te pueda ubicar mejor","No es tan dificil aqui esta el edificio","Este mapa te puede ayudar"]
ROUTE = ["Aqui te mostramos una forma en la que puedes llegar a tu destino","Que tal este camino","Porque no sigues esta ruta","Intenta esto"]

NONE = ["Lo siento pero no te entendi","el problema es realmente duro, intentalo formular de otra manera","no se","me corchaste"]
NONE_BUILDING = ["Lo siento, no se","Me conrchaste","Intente preguntar por otra cosa","No tengo informacion acerca del edificio","No se como solucionar lo que preguntaste","No tengo informacion pero sigue intentando tal vez en el futuro pueda responderte",":p, no se, investigare para responderte"]
GREETINGS = {
  greet: ["hola\n", "hi\n", "hello\n","hey\n"],
  about: ["bien, como vas\n", "bien, como has estado\n", "bien, que tal la u","bien, que tal la vida\n","bien, como van las cosas\n","genial, tu\n"],
  about_doing: ["esperando para resolverte cualquier duda o problema que tengas \nque haces","he estado esperando, pero ahora estoy feliz porque ya pude conocerte, \nque has hecho","tengo planeado ponerme a tu disposicion para solucionar cualquier duda que tengas \nque tienes planeado"]
}

MENU_REPLIES = [
  {
    content_type: 'text',
    title: 'Informacion',
    payload: 'INFORMATION'
  },
  {
    content_type: 'text',
    title: 'Rutas',
    payload: 'ROUTE'
  },
  {
    content_type: 'text',
    title: 'Localizacion',
    payload: 'LOCATION'
  }
].freeze

Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when 'INFORMATION'
    example_information(sender_id)
    way_for_any_input
  when 'ROUTE'
    example_route(sender_id)
    way_for_any_input
  when 'LOCATION'
    example_location(sender_id)
    way_for_any_input
  end
end

def example_information(id)
  say(id,"Porque no preguntas: "+ IDIOMS[:general].sample)
end

def example_location(id)
  say(id,"Porque no preguntas: "+ IDIOMS[:position].sample)
end

def example_route(id)
  say(id,"Porque no preguntas: "+ IDIOMS[:route].sample)
end

def say(id,text,menu = nil)
  message_options = {
  recipient: { id: id },
  message: { text: text }
  }
  if menu
    message_options[:message][:quick_replies] = menu
  end
  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
end

def way_for_any_input
  Bot.on :message do |message|
    if is_text_message?(message)
      if message.text == "Informacion"
         message.reply(text: "Como por ejemplo: "+ IDIOMS[:general].sample)
      elsif message.text == "Rutas"
        message.reply(text: "Podrias preguntar: " + IDIOMS[:route].sample)
      elsif message.text == "Localizacion"
        message.reply(text: "Yo puedo responder: " + IDIOMS[:position].sample)
      else
        result = unbot(message.text)
        case result["topScoringIntent"]["intent"]
        when "Greeting"
          v = true
          result["entities"].each do |a|
            if a["type"] == "what"
              v = false
              break
            end
           end
           if v
             show_replies_menu(message.sender['id'],MENU_REPLIES,result["entities"])
             else
             show_replies_menu_what(message.sender['id'],MENU_REPLIES)
           end
        when "LocateBuilding"
          handle_location_building(message,message.sender['id'],result["entities"])
        when "Route"
          handle_route(message,result["entities"])
        when "ShowInformation"
          handle_information(message,result["entities"])
        else
          show_replies_menu_none(message.sender['id'],MENU_REPLIES)
        end
      end
    else
      message.reply(text: "Necesitamos un texto para poder trabajar")
    end
  end
end

def show_replies_menu_none(id,menu)
  text = "Selecciona alguna opcion para que veas de lo que soy capaz"
  say(id,text,menu)
  way_for_any_input
end

def show_replies_menu_what(id,menu)
  text = "Seleciona alguno de los botones para que veas de lo que soy capaz"
  say(id,text,menu)
  way_for_any_input
end

def show_replies_menu(id,menu,entities)
  greet = true
  about = true
  about_doing = true
  without_answer = true
  if entities != nil && !entities.empty?
    text = ""
    entities.each do |a|
      if a["type"] == "greet" && greet
        text = text + GREETINGS[:greet].sample + ""
        greet = false
        break
      end
    end
    entities.each do |a|
      if a["type"] == "about" && about
        text = text + GREETINGS[:about].sample + ""
        about = false
        break
      end
    end
    entities.each do |a|
      if a["type"] == "about_doing" && about_doing
        text = text + GREETINGS[:about_doing].sample + ""
        about_doing = false
        break
      end
    end
    entities.each do |a|
      if a["type"] == "without_answer" && without_answer
        text = text + WITHOUT_ANSWERS.sample + ""
        without_answer = false
        break
      end
    end
  else
    text = "ok"
  end
  say(id,text,menu)
  way_for_any_input
end

def handle_location_building(message,id,entities)
  result = HTTParty.post(BACK,:body => {
               :data => entities
             }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )
  if result["result"]["status"] == "ok"
    url = "https://www.google.com/maps/search/?api=1&query=#{result["result"]["data"]["lat"]},#{result["result"]["data"]["lng"]}"
    say(id,"#{LOCALITATION.sample}\n#{url}")
    message.reply(
      attachment: {
        type: 'image',
        payload: {
          url: result["result"]["data"]["image"]["url"]
        }
      }
    )
  else
    say(id,NONE_BUILDING.sample)
  end
  way_for_any_input
end

def handle_route(message,entities)
  result = HTTParty.post(BACK_ROUTE,:body => {
               :data => entities
             }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )
  if result["result"]["status"] == "ok"
    message.reply(text: "#{ROUTE.sample}  \n"+result["result"]["message"])
  else
    message.reply(text: NONE_BUILDING.sample)
  end
  way_for_any_input
end

def handle_information(message,entities)
  result = HTTParty.post(BACK_INFORMATION,:body => {
               :data => entities
             }.to_json,
    :headers => { 'Content-Type' => 'application/json' } )
  if result["result"]["status"] == "ok"
    message.reply(text: result["result"]["message"])
  else
    message.reply(text: NONE_BUILDING.sample)
  end
  way_for_any_input
end

def unbot(message)
  response = HTTParty.get(UNBOT+encode_ascii(message))
  parsed = JSON.parse(response.body)
end

def encode_ascii(s)
  Addressable::URI.parse(s).normalize.to_s
end

def is_text_message?(message)
  !message.text.nil?
end

way_for_any_input
