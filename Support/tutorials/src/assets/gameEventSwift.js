export default `enum GameEvent: EmittableEvent {
  case looted(items: [Item])
  case damaged(target: Node)
  case dropped(items: [Item])
}`
