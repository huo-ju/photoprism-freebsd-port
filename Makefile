# $FreeBSD$

PORTNAME=	photoprism
DISTVERSION=	g20210222
CATEGORIES=	www

MAINTAINER=	huoju@devep.net
COMMENT=	Personal Photo Management powered by Go and Google TensorFlow

LICENSE=	AGPLv3

RUN_DEPENDS=  ffmpeg:multimedia/ffmpeg
BUILD_DEPENDS=  ${RUN_DEPENDS} \
	bash:shells/bash \
	wget:ftp/wget \
	go:lang/go \
	python3:lang/python3 \
	bazel:devel/bazel029

USES= gmake

USE_GITHUB=	yes
GH_ACCOUNT=	photoprism
GH_PROJECT=	photoprism
GH_TAGNAME=     ac5a9d5ee435ae9233f25740128049dbb329a9d2

USE_RC_SUBR=    photoprism
PHOTOPRISM_DATA_DIR=      /var/db/photoprism
SUB_LIST+=      PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=      pkg-install pkg-message

TF_VERSION = 1.15.2

OPTIONS_SINGLE=		CPUFEATURE 
OPTIONS_SINGLE_CPUFEATURE=	NONE AVX AVX2
OPTIONS_DEFAULT = NONE
CPUFEATURE_DESC=          Enable tensorflow using features available on your CPU
NONE_VARS=	BAZEL_COPT=""
AVX_VARS=	BAZEL_COPT="--copt=-march=core-avx-i --host_copt=-march=core-avx-i"
AVX2_VARS=	BAZEL_COPT="--copt=-march=core-avx2 --host_copt=-march=core-avx2"


.include <bsd.port.options.mk>
.if ${OPSYS} == FreeBSD && ${OSVERSION} > 1100000 && ${OSVERSION} < 1200000
EXTRA_PATCHES=	${PATCHDIR}/extra-patch-docker_tensorflow_tensorflow-1.15.2_tensorflow_core_protobuf_autotuning.proto
.endif

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh
	cd ${WRKSRC}/docker/tensorflow && gmake download


pre-build:
	@${REINPLACE_CMD} -e 's|0\.26\.1|0\.29\.0|g' ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/configure.py
	cd ${WRKSRC}/docker/tensorflow/tensorflow-${TF_VERSION} && ./configure && bazel --output_user_root="${WRKDIR}/.bazel" build --config=opt //tensorflow:libtensorflow.so ${BAZEL_COPT} && ./create_archive.sh freebsd-cpu ${TF_VERSION}
	@${REINPLACE_CMD} -e 's|	go build -v ./...|	CGO_CFLAGS="-I${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/include" CGO_LDFLAGS="-L${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib" go build -v ./cmd/... ./internal/... ./pkg/...|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|	scripts/build.sh debug|	CGO_CFLAGS="-I${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/include" CGO_LDFLAGS="-L${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib" scripts/build.sh debug|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|PHOTOPRISM_VERSION=.*|PHOTOPRISM_VERSION=${GH_TAGNAME}|' ${WRKSRC}/scripts/build.sh

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${INSTALL_LIB} ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib/libtensorflow.so ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1.15.2
	${INSTALL_LIB} ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib/libtensorflow_framework.so ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1.15.2
	${LN} -fs libtensorflow_framework.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1
	${LN} -fs libtensorflow.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
