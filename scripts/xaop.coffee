# Description:
#   XAOP scripts

# Notes
#   Mostly for ordering food

module.exports = (robot) ->
  robot.hear /I want pizza/i, (res) ->
    res.send "Who doesn't? Try typing '@hubby: pizza <4 staggioni>' and I'll see what I can do!"

  robot.respond /pizza1 (.+)/i, (msg, e) ->
    pizza = msg.match[1]
    msg.reply "One pizza #{pizza} coming up (reply)!"

  robot.respond /pizza2/i, (msg) ->
    pizza = msg.match[1]
    msg.send "One pizza #{pizza} coming up, you want free beer too?"

  robot.respond /pizza3 (.*)/i, (msg) ->
    pizza = msg.match[1]
    pizza_orders = robot.brain.get('pizzaOrderss') or []
    pizza_orders.push pizza
    robot.brain.set 'pizzaOrderss', pizza_orders
    msg.reply "One pizza #{pizza} ordered, already #{pizza_orders.length} on the list"