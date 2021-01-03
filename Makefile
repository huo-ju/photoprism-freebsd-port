# $FreeBSD$

PORTNAME=	photoprism
DISTVERSION=	g20201231
CATEGORIES=	www

MAINTAINER=	huoju@devep.net
COMMENT=	Personal Photo Management powered by Go and Google TensorFlow

LICENSE=	AGPLv3

RUN_DEPENDS=  ffmpeg:multimedia/ffmpeg
BUILD_DEPENDS=  ${RUN_DEPENDS} \
	bash:shells/bash \
	go:lang/go\
	python3:lang/python3 \
	bazel:devel/bazel029

USES= gmake

USE_GITHUB=	yes
GH_ACCOUNT=	photoprism
GH_PROJECT=	photoprism
GH_TAGNAME=	8e22fbf8f6bb873eb72988c0def925d402753125

USE_RC_SUBR=    photoprism
PHOTOPRISM_DATA_DIR=      /var/photoprism
SUB_LIST+=      PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=      pkg-install pkg-message

TF_VERSION = 1.15.2

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh

pre-build:
	cd ${WRKSRC} && ${MV} docker _docker
	cd ${WRKSRC}/_docker/tensorflow && $(MAKE) download
	@${REINPLACE_CMD} -e 's|0\.26\.1|0\.29\.0|g' ${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/configure.py
	cd ${WRKSRC}/_docker/tensorflow/tensorflow-${TF_VERSION} && ./configure && bazel build --config=opt //tensorflow:libtensorflow.so && ./create_archive.sh freebsd-cpu ${TF_VERSION}
	@${REINPLACE_CMD} -e 's|	go build -v|	CGO_CFLAGS="-I${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/include" CGO_LDFLAGS="-L${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib" go build -v|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|	scripts/build.sh debug|	CGO_CFLAGS="-I${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/include" CGO_LDFLAGS="-L${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib" scripts/build.sh debug|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|PHOTOPRISM_VERSION=.*|PHOTOPRISM_VERSION=${GH_TAGNAME}|' ${WRKSRC}/scripts/build.sh

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${INSTALL_LIB} ${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib/libtensorflow.so ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1.15.2
	${INSTALL_LIB} ${WRKSRC}/_docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib/libtensorflow_framework.so ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1.15.2
	${LN} -fs libtensorflow_framework.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1
	${LN} -fs libtensorflow.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
