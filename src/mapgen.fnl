(import-macros {: vec2-op} :geom-macros)
(local lume (require :lib.lume))
(local geom (require :geom))
(local util (require :util))
(local pp util.pp)

(local mapgen {})

(fn mapgen.generate-level [level w h]
  ;; place at least 4 rooms
  (fn gen-rooms []
    (let [rooms (mapgen.random-polygons w h 10)]
      (if (> (length rooms) 3) rooms (gen-rooms))))
  (local rooms (gen-rooms))
  (local bboxes (icollect [_ room (ipairs rooms)]
                  (mapgen.polygon-bounding-box room)))
  (local centers (icollect [_ v (ipairs bboxes)]
                   [(mapgen.bounding-box-center v)]))

  ;; join them into level border
  (local level-border (mapgen.join-polygons (unpack rooms)))

  ;; place actors...
  (local actor-list [])
  (fn add-actor [kind room distance]
    (let [pos [(mapgen.random-point-near-polygon-center room nil distance)]]
      (table.insert actor-list [kind pos])))

  ;; put player in room of own
  (local player-room-index (love.math.random 1 (length rooms)))
  (local player-room (. rooms player-room-index))
  (add-actor :player player-room 0)

  ;; place 10 enemies
  (while (< (length actor-list) 10)
    (each [index poly (ipairs rooms)]
        (when (not= index player-room-index)
          (when (< (love.math.random) 0.5)
            (add-actor :grid-bug poly 1))
          (when (< (love.math.random) 0.3)
            (add-actor :killer-tomato poly 0.5)))))

  ;; place stairs down in furthest room from player
  (local (_ furthest-room-idx) (util.index-of-furthest
                                (. centers player-room-index)
                                centers))
  (add-actor :stairs-down (. rooms furthest-room-idx) 0)

  (values level-border actor-list))

(fn mapgen.random-polygons [w h max]
  ;; w and h are maximum size
  (var polygons [])
  (for [i 1 100 &until (< max (length polygons))]
    (let [margin 150
          size (love.math.random 30 120)
          next-poly (geom.polygon
                     {
                      :origin [(love.math.random margin (- w margin))
                               (love.math.random margin (- h margin))]
                      : size
                      :sides (/ size 10)
                      :angle (* 2 math.pi (love.math.random))})
          collision?
          (accumulate [collision? false
                       _ poly (ipairs polygons)
                       &until collision?]
            (geom.rect-in-rect?
             (mapgen.polygon-bounding-box poly)
             (mapgen.polygon-bounding-box next-poly)))]
      (if (not collision?) (table.insert polygons next-poly))))
  polygons)

(fn mapgen.polygon-bounding-box [p]
  (accumulate [[min-x min-y max-x max-y]
               [math.huge math.huge (- math.huge) (- math.huge)]
               _ [x y] (ipairs p)]
    [
     (math.min min-x x)
     (math.min min-y y)
     (math.max max-x x)
     (math.max max-y y)]))

(fn mapgen.random-point-in-rect [x y x2 y2]
  (let [[w h] [(- x2 x) (- y2 y)]]
    (values
     (+ x (* w (love.math.random)))
     (+ y (* h (love.math.random))))))

(fn mapgen.bounding-box-center [[x1 y1 x2 y2]]
  (values (/ (+ x1 x2) 2) (/ (+ y1 y2) 2)))

(fn mapgen.random-point-in-polygon [polygon ?rect]
  (let [rect (or ?rect (mapgen.polygon-bounding-box polygon))
        point [(mapgen.random-point-in-rect (unpack rect))]]
    (if (geom.point-in-polygon? point polygon)
        (unpack point)
        (mapgen.random-point-in-polygon polygon rect))))

(fn mapgen.random-point-near-polygon-center [polygon ?rect ?distance]
  (let [rect (or ?rect (mapgen.polygon-bounding-box polygon))
        distance (or ?distance 0.8)
        point [(mapgen.random-point-in-rect (unpack rect))]
        center [(mapgen.bounding-box-center rect)]
        point [(vec2-op #(lume.lerp $1 $2 distance) center point)]]
    (if (geom.point-in-polygon? point polygon)
        (unpack point)
        (mapgen.random-point-near-polygon-center polygon rect distance))))

(fn mapgen.join-polygons [...]
  (var poly-out nil)
  (while (not poly-out)
    (let [polygon-list (lume.shuffle [...])]
      (set poly-out
        (faccumulate [poly-out (. polygon-list 1)
                      i 2 (length polygon-list)
                      &until (not poly-out)]
          (mapgen.try-join-2-polygons poly-out (. polygon-list i))))))
  poly-out)

(fn mapgen.try-join-2-polygons [poly1 poly2]
  (let [point1 [(mapgen.random-point-in-polygon poly1)]
        point2 [(mapgen.random-point-in-polygon poly2)]
        lineseg [point1 point2]
        (_ _ vindex1) (geom.lineseg-polygon-intersection lineseg poly1)
        (_ _ vindex2) (geom.lineseg-polygon-intersection lineseg poly2)
        polygon-out (lume.concat
                     (lume.slice poly1 1 vindex1)
                     (lume.slice poly2 (+ 1 vindex2))
                     (lume.slice poly2 1 vindex2)
                     (lume.slice poly1 (+ 1 vindex1)))
        min-angle (/ math.pi 36) ; no angles less than 5 degrees
        valid (geom.polygon-valid? polygon-out (/ math.pi 90))]
    (and valid polygon-out)))

mapgen
