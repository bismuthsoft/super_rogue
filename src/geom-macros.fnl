(fn vec-op [stride op ...]
  `(values
    ,(unpack
      (fcollect [i 1 stride]
       `(,op
         ,(unpack
           (icollect [_ v (ipairs [...])]
             `(. ,v ,i))))))))

(fn vec2-op [op ...]
  `(values
    (,op ,(unpack (icollect [_ v (ipairs [...])] `(. ,v 1))))
    (,op ,(unpack (icollect [_ v (ipairs [...])] `(. ,v 2))))))

{: vec-op : vec2-op}
