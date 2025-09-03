import { Sticky } from "./sticky.js";

describe("Sticky Component", () => {
  let mockElement;
  let stickyInstance;
  let scrollEventListener;

  beforeEach(() => {
    document.body.classList.add("nhsuk-frontend-supported");

    // Create a mock DOM element
    document.body.innerHTML = `<div id="mock-element" style="position: sticky; top: 20px;"></div>`;
    mockElement = document.getElementById("mock-element");

    // Mock getBoundingClientRect
    Object.defineProperty(mockElement, "getBoundingClientRect", {
      value: jest.fn(() => ({ top: 0 })),
      configurable: true,
    });

    // Mock window.getComputedStyle
    Object.defineProperty(window, "getComputedStyle", {
      value: jest.fn(() => ({
        top: "20px",
      })),
      writable: true,
    });

    // Mock window.addEventListener and capture scroll listener
    const originalAddEventListener = window.addEventListener;
    window.addEventListener = jest.fn((event, listener) => {
      if (event === "scroll") {
        scrollEventListener = listener;
      }
      originalAddEventListener.call(window, event, listener);
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  describe("Initialization", () => {
    test("should initialize with correct properties", () => {
      stickyInstance = new Sticky(mockElement);

      expect(stickyInstance.stickyElement).toBe(mockElement);
      expect(stickyInstance.stickyElementTop).toBe(20);
      expect(window.getComputedStyle).toHaveBeenCalledWith(mockElement);
      expect(window.addEventListener).toHaveBeenCalledWith(
        "scroll",
        expect.any(Function),
      );
    });

    test("should have correct moduleName", () => {
      expect(Sticky.moduleName).toBe("app-sticky");
    });

    test("should call determineStickyState on initialization", () => {
      const spy = jest.spyOn(Sticky.prototype, "determineStickyState");
      stickyInstance = new Sticky(mockElement);
      expect(spy).toHaveBeenCalled();
    });
  });

  describe("determineStickyState method", () => {
    beforeEach(() => {
      stickyInstance = new Sticky(mockElement);
    });

    test("should set data-stuck to `true` when element is at or above threshold", () => {
      // Element is at the top (currentTop = 0, threshold = 20)
      mockElement.getBoundingClientRect.mockReturnValue({ top: 0 });

      stickyInstance.determineStickyState();

      expect(mockElement.dataset.stuck).toBe("true");
    });

    test("should set data-stuck to `true` when element above threshold", () => {
      mockElement.getBoundingClientRect.mockReturnValue({ top: 10 });

      stickyInstance.determineStickyState();

      expect(mockElement.dataset.stuck).toBe("true");
    });

    test("should set data-stuck to `true` when element at threshold", () => {
      mockElement.getBoundingClientRect.mockReturnValue({ top: 20 });

      stickyInstance.determineStickyState();

      expect(mockElement.dataset.stuck).toBe("true");
    });

    test("should set data-stuck to `false` when element below threshold", () => {
      mockElement.getBoundingClientRect.mockReturnValue({ top: 30 });

      stickyInstance.determineStickyState();

      expect(mockElement.dataset.stuck).toBe("false");
    });
  });

  describe("Scroll behavior", () => {
    beforeEach(() => {
      jest.useFakeTimers();

      // Clear any existing event listeners
      window.removeEventListener = jest.fn();

      stickyInstance = new Sticky(mockElement);
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    test("should respond to scroll events", () => {
      mockElement.getBoundingClientRect.mockReturnValue({ top: 10 });

      // Make sure we have the listener
      expect(scrollEventListener).toBeDefined();

      // Trigger scroll event
      scrollEventListener();

      expect(mockElement.dataset.stuck).toBe("true");
    });
  });

  describe("Throttle functionality", () => {
    beforeEach(() => {
      jest.useFakeTimers();
      stickyInstance = new Sticky(mockElement);
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    test("should throttle function calls", () => {
      const mockCallback = jest.fn();
      const throttledCallback = stickyInstance.throttle(mockCallback, 100);

      // Call multiple times rapidly
      throttledCallback();
      throttledCallback();
      throttledCallback();

      // Should only be called once
      expect(mockCallback).toHaveBeenCalledTimes(1);

      // Fast forward past throttle limit
      jest.advanceTimersByTime(100);

      // Now should allow another call
      throttledCallback();
      expect(mockCallback).toHaveBeenCalledTimes(2);
    });

    test("should preserve context and arguments in throttled function", () => {
      const mockCallback = jest.fn();
      const throttledCallback = stickyInstance.throttle(mockCallback, 100);

      throttledCallback("arg1", "arg2");

      expect(mockCallback).toHaveBeenCalledWith("arg1", "arg2");
    });
  });

  describe("Integration with different CSS top values", () => {
    test("should handle different top values correctly", () => {
      // Mock different computed style top value
      window.getComputedStyle.mockReturnValue({ top: "50px" });

      stickyInstance = new Sticky(mockElement);

      expect(stickyInstance.stickyElementTop).toBe(50);

      // Test with element above new threshold
      mockElement.getBoundingClientRect.mockReturnValue({ top: 30 });
      stickyInstance.determineStickyState();
      expect(mockElement.dataset.stuck).toBe("true");

      // Test with element below new threshold
      mockElement.getBoundingClientRect.mockReturnValue({ top: 60 });
      stickyInstance.determineStickyState();
      expect(mockElement.dataset.stuck).toBe("false");
    });
  });
});
