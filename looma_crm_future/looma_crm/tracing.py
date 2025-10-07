"""
LoomaCRM-AI Jaeger链路追踪支持
"""

import logging
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.semconv.resource import ResourceAttributes
from opentelemetry.instrumentation.requests import RequestsInstrumentor

logger = logging.getLogger(__name__)

def init_tracing():
    """初始化Jaeger链路追踪"""
    try:
        # 创建资源
        resource = Resource.create({
            ResourceAttributes.SERVICE_NAME: "looma-crm",
            ResourceAttributes.SERVICE_VERSION: "1.0.0",
            ResourceAttributes.DEPLOYMENT_ENVIRONMENT: "development",
        })
        
        # 创建TracerProvider
        trace.set_tracer_provider(TracerProvider(resource=resource))
        tracer = trace.get_tracer(__name__)
        
        # 创建Jaeger导出器
        jaeger_exporter = JaegerExporter(
            agent_host_name="localhost",
            agent_port=14268,
        )
        
        # 创建Span处理器
        span_processor = BatchSpanProcessor(jaeger_exporter)
        trace.get_tracer_provider().add_span_processor(span_processor)
        
        # 自动instrument requests库
        RequestsInstrumentor().instrument()
        
        logger.info("Jaeger tracing initialized successfully")
        return tracer
        
    except Exception as e:
        logger.error(f"Failed to initialize Jaeger tracing: {e}")
        return None

def get_tracer():
    """获取tracer实例"""
    return trace.get_tracer(__name__)

def start_span(name, **kwargs):
    """开始一个新的span"""
    tracer = get_tracer()
    return tracer.start_span(name, **kwargs)

def add_span_attributes(span, attributes):
    """添加span属性"""
    for key, value in attributes.items():
        span.set_attribute(key, value)
