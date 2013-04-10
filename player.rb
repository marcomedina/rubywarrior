class Player

  @@abilities = [:attack!, :feel, :health, :rest!, :shoot!, :rescue!, :pivot!, :look]
  @@directions = [:backward, :forward, :right, :left]
  @@things_can_feel = [:enemy, :captive, :wall, :stairs, :empty]
  @@first_time = true

  def play_turn(warrior)

    @warrior = warrior

    #First Turn
    if @@first_time

      @@abilities.each do |name|
        var_name = name.to_s
        var_name.sub!(/.{1}$/,'') if var_name.split('').last == "!"
        instance_variable_set("@can_#{var_name}", @warrior.methods.include?(name))
        puts "can_#{var_name}: #{@warrior.methods.include?(name)}"
      end


      if @can_health
        @MAX_HEALTH = 20
        @MIN_HEALTH = 14
        @last_health = @warrior.health
      end


      @reached_walls = []
      @archer = false
      @recover = false
      @stairs_found = false
      @has_pivoted = false

    end



    def last_health
      if @can_health
        @last_health = @warrior.health
      end
    end

    def remaining_directions
      if @can_feel
        @remaining_directions = @@directions - @reached_walls
      end
    end

    def feel_around
      if @can_feel

        @@things_can_feel.each { |name| instance_variable_set("@felt_#{name}", []) }


        @@directions.each do |direction|

          @@things_can_feel.each do |thing|
            qthing = "#{thing}?"
            if @warrior.feel(direction).send(qthing)
              eval("@felt_#{thing}") << direction
              if thing == :wall
                @reached_walls << direction unless @reached_walls.include?(direction)
              end
            end
          end

        end

        @@things_can_feel.each { |name| puts "@felt_#{name} => #{eval("@felt_#{name}")}" }
        puts "@reached_walls => #{@reached_walls}"

      end
    end

    def look_around
      if @can_look
        @seen = []

        seen = @warrior.look(@remaining_directions.first)
        seen.each do |seen_space|
          if seen_space.enemy? || seen_space.captive?
            @seen << seen_space
          end
        end
      end
    end

    def archer?
      if @can_health
        if @felt_enemy.any? == false && @warrior.health < @last_health
          @archer = true
          @recover = false
          false
        elsif @archer && @warrior.health == @last_health && @felt_enemy.any? == false
          @archer = false
        end
      end
    end

    def stairs_found?
      if @can_feel && @felt_stairs.any?
        @stairs_found = true
      end
    end

    def rescue_captives
      if @can_rescue && @felt_captive.any?
        @warrior.rescue!(@felt_captive.first)
      else
        false
      end
    end

    def fight
      if @can_shoot && @felt_enemy.any? == false && @seen.any? && @seen.first.enemy?
        @warrior.shoot!(@remaining_directions.first)
      elsif @can_attack && @felt_enemy.any?
        if @can_feel
          @warrior.attack!(@felt_enemy.first)
        else
          @warrior.attack!
        end
      else
        false
      end
    end

    def walk
      if @can_feel
        if @remaining_directions.size > 1 && @stairs_found && @has_pivoted == false
          @warrior.pivot!
          @has_pivoted = true
        else
          @warrior.walk!(@remaining_directions.first)
        end
      else
        @warrior.walk!
      end
    end

    def rest
      if @can_rest
        if @archer == false
          if @felt_enemy.any? == false && @last_health <= @MIN_HEALTH && @felt_stairs.any? == false
            @warrior.rest!
          elsif @warrior.health > @last_health && @warrior.health < @MAX_HEALTH
            @warrior.rest!
          else
            @recover = false
          end
        else
          false
        end
      else
        false
      end
    end

    def fall_back
      if @can_health && @can_rest && @archer == false
        if @felt_enemy.any? && @last_health <= @MIN_HEALTH
          @warrior.walk!(@felt_empty.first)
          @recover = true
        else
          false
        end
      else
        false
      end
    end

    feel_around
    remaining_directions
    look_around
    archer?
    stairs_found?

    #Start
    rescue_captives || rest || fall_back || fight || walk

    @@first_time = false
    last_health
  end
end