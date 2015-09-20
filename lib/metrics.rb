module LogPlugin
  module Metrics
    extend ActiveSupport::Concern
    
    # Examples:
    # Log.interval(Date.yesterday).views
    # Log.interval(Date.parse('2015-05-11'), Date.parse('2015-05-17')).visits

    module ClassMethods
      def dates
        order(:created_at).pluck('created_at::date').uniq.map(&:to_date)
      end
      
      # Просмотры
      def views
        count
      end

      # Визиты
      # test: Log.where.not(first_id: nil).where(:created_at => from .. to).pluck(:first_id).uniq.size
      def visits
        select(:first_id).where('id = first_id').count
      end

      # Посетители
      # test: Log.where.not(user_id: nil).where(:created_at => from .. to).pluck(:user_id).uniq.size
      def users
        select(:user_id).where('user_id is not null').uniq.count
      end

      # Контроллеры
      def controllers
        where('controller is not null').uniq.pluck(:controller)
      end

      def popular_controllers(lim = 0)
        logs = sort_by_count(controllers, top: lim, keep_count: true) do |x|
          where(controller: x).views
        end
        logs.to_h
      end

      # Контроллеры страниц – источников переходов
      def referer_controllers
        where('referer_controller is not null').uniq.pluck(:referer_controller)
      end

      def popular_referer_controllers(lim = 0)
        logs = sort_by_count(referer_controllers, top: lim, keep_count: true) do |x|
          where(referer_controller: x).views
        end
        logs.to_h
      end

      # Пути
      def paths
        ids = select(:first_id).uniq.pluck(:first_id).compact
        result = {}
        ids.each { |id| result[id] = where(first_id: id).order(:created_at) }
        result
      end

      # Наиболее посещаемые страницы
      # options - top: 20, group_by: :query | :controller | :controller_and_action
      def popular(options = {})
        top = options.delete(:top) || 20
        grp = options.delete(:group_by) || :query
        grp = grp.to_sym
        case grp
          when :query, :controller
            all.group(grp).order('count(*) desc').limit(top).count
          when :controller_and_action
            hash = all.group(:controller, :action).order('count(*) desc').limit(top).count
            hash.map { |k, count| ["#{k[0]}##{k[1]}", count] }.to_h
          else
            raise 'Invalid "group_by" value'
        end
      end

      # Страницы входа
      def enter_pages
        where('first_id = id')
      end

      # Страницы выхода
      def exit_pages
        ids = select(:first_id).uniq.pluck(:first_id)
        ids.map { |id| order(created_at: :desc).find_by(first_id: id) }
      end

      # array: [value, ...]
      # value may be scalar or array
      def sort_by_count(array, options = {})
        top = options.delete(:top)
        keep_count = options.delete(:keep_count)
        
        # посчитать и отсортировать
        a = array.map { |value| [value, yield(value)] }
        a.sort_by!(&:last)
        # отбросить количество из результата
        a.map!(&:first) unless keep_count

        a = a.reverse[0 ... top] if top && top > 0
        a
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  Log.send(:include, LogPlugin::Metrics) unless Log.included_modules.include?(LogPlugin::Metrics)
end
