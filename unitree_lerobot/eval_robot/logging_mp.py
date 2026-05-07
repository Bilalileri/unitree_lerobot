import logging


DEBUG = logging.DEBUG
INFO = logging.INFO
WARNING = logging.WARNING
ERROR = logging.ERROR


def basic_config(*args, **kwargs):
    return logging.basicConfig(*args, **kwargs)


def basicConfig(*args, **kwargs):
    return logging.basicConfig(*args, **kwargs)


def get_logger(name=None, level=None):
    logger = logging.getLogger(name)
    if level is not None:
        logger.setLevel(level)
    return logger


def getLogger(name=None, level=None):
    return get_logger(name, level)
