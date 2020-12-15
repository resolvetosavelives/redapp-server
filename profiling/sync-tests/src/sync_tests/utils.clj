(ns sync-tests.utils)

(defn now []
  (.getTime (java.util.Date.)))

(defn timing [body-fn]
  (let [start (now)
        result (body-fn)
        end (now)]
    {:elapsed (- end start)
     :start start
     :end end
     :response result}))