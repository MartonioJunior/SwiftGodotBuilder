extension Double {
  var asTimeString: String {
    let minutes = Int(self) / 60
    let seconds = Int(self) % 60
    let centiseconds = Int(truncatingRemainder(dividingBy: 1) * 100)
    if minutes > 0 {
      return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
    }
    return String(format: "%02d.%02d", seconds, centiseconds)
  }
}
