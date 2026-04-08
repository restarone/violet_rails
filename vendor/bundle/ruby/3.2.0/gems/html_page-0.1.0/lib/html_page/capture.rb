module HtmlPage
  class Capture
    def initialize(context, &block)
      @context = context
      @block = block || NullBlock.new
    end

    def capture
      if block.arity > 0
        block.call(*block_arguments)
      end

      [head.content, body.content]
    end

    private

    attr_reader :block, :context

    def block_arguments
      [head, body].first(block.arity)
    end

    def body
      @body ||= Block.new(context)
    end

    def head
      @head ||= begin
        if block.arity < 1
          BlockWithoutArguments.new(context, &block)
        else
          Block.new(context)
        end
      end
    end

    class BlockWithoutArguments
      def initialize(context, &block)
        @context = context
        @block = block
      end

      def content
        @context.with_output_buffer(&@block)
      end
    end
    private_constant :BlockWithoutArguments

    class Block
      def initialize(context)
        @context = context
        @content = []
      end

      def append(&block)
        @content.push(@context.with_output_buffer(&block))
        nil
      end

      def content
        @content.join
      end
    end
    private_constant :Block

    class NullBlock
      def arity
        1
      end

      def call(*)
      end
    end
    private_constant :NullBlock
  end
end
