(local particle {})

(fn particle.spawn [s pos angle props]
  {:kind "particle"
   :name "particle"
   :update particle.update
   : angle
   : pos
   :always-visible? true
   :moving? true
   :color props.color
   :char props.char
   :char-scale props.char-scale
   :show-line props.show-line
   :lifetime props.lifetime
   :speed props.speed})

particle
