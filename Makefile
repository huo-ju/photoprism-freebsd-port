# $FreeBSD$

PORTNAME=	photoprism
DISTVERSION=	g20211018
CATEGORIES=	www

MAINTAINER=	huoju@devep.net
COMMENT=	Personal Photo Management powered by Go and Google TensorFlow

LICENSE=	AGPLv3

RUN_DEPENDS=  ffmpeg:multimedia/ffmpeg \
	exiftool:graphics/p5-Image-ExifTool
EXTRACT_DEPENDS=  ${RUN_DEPENDS} \
	bash:shells/bash \
	bazel:devel/bazel029 \
	git:devel/git \
	gmake:devel/gmake \
	go:lang/go \
	npm:www/npm-node14 \
	wget:ftp/wget

USES= gmake python:3.6+,build

USE_GITHUB=	yes
GH_ACCOUNT=	photoprism
GH_PROJECT=	photoprism
GH_TAGNAME=     e200f322be07f6ada9cd88902ba65372c69f0364

USE_RC_SUBR=    photoprism
PHOTOPRISM_DATA_DIR=      /var/db/photoprism
SUB_LIST+=      PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=      pkg-install pkg-message

TF_VERSION = 1.15.2

OPTIONS_SINGLE=		CPUFEATURE 
OPTIONS_SINGLE_CPUFEATURE=	NONE AVX AVX2
OPTIONS_DEFAULT = AVX
CPUFEATURE_DESC=          Enable AVX CPU extensions for Tensorflow
NONE_VARS=	BAZEL_COPT=""
AVX_VARS=	BAZEL_COPT="--copt=-march=core-avx-i --host_copt=-march=core-avx-i"
AVX2_VARS=	BAZEL_COPT="--copt=-march=core-avx2 --host_copt=-march=core-avx2"


TF_ENV=		TF_DOWNLOAD_CLANG=0 TF_NEED_MPI=0 TF_SET_ANDROID_WORKSPACE=0 CC_OPT_FLAGS="-march=native -Wno-sign-compare"
OPTIONS_DEFINE=	TF_NEED_OPENCL_SYCL TF_NEED_ROCM TF_NEED_CUDA
TF_NEED_OPENCL_SYCL_DESC=	OpenCL SYCL
TF_NEED_OPENCL_SYCL_VARS=	TF_ENV+="TF_NEED_OPENCL_SYCL=1"
TF_NEED_OPENCL_SYCL_VARS_OFF=	TF_ENV+="TF_NEED_OPENCL_SYCL=0"
TF_NEED_ROCM_DESC=	ROCm
TF_NEED_ROCM_VARS=	TF_ENV+="TF_NEED_ROCM=1"
TF_NEED_ROCM_VARS_OFF=	TF_ENV+="TF_NEED_ROCM=0"
TF_NEED_CUDA_DESC=	CUDA
TF_NEED_CUDA_VARS=	TF_ENV+="TF_NEED_CUDA=1"
TF_NEED_CUDA_VARS_OFF=	TF_ENV+="TF_NEED_CUDA=0"



.include <bsd.port.options.mk>
.if ${OPSYS} == FreeBSD && ${OSVERSION} > 1100000 && ${OSVERSION} < 1200000
EXTRA_PATCHES=	${PATCHDIR}/extra-patch-docker_tensorflow_tensorflow-1.15.2_tensorflow_core_protobuf_autotuning.proto
.endif

.if ${OPSYS} == FreeBSD && ${OSVERSION} > 1200000 && ${OSVERSION} < 1300000
EXTRA_PATCHES=  ${PATCHDIR}/extra-patch-docker_tensorflow_tensorflow-1.15.2_third_party_repo.bzl
.endif

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-facenet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh
	cd ${WRKSRC}/docker/tensorflow && gmake download

pre-build:
	@${REINPLACE_CMD} -e "s|\$$PYTHON_BIN_PATH|$(PYTHON_CMD)|" ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/configure
	@${REINPLACE_CMD} -e 's|0\.26\.1|0\.29\.0|g' ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/configure.py
	@${REINPLACE_CMD} -e "s|'--batch'|\'--batch\', \'--output_user_root=\"${WRKDIR}/.bazel\"\'|" ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/configure.py
	cd ${WRKSRC}/docker/tensorflow/tensorflow-${TF_VERSION} && PYTHON_BIN_PATH="$(PYTHON_CMD)" PYTHON_LIB_PATH="$(PYTHON_CMD)/site-packages" TF_ENABLE_XLA="False" ${TF_ENV} ./configure
	cd ${WRKSRC}/docker/tensorflow/tensorflow-${TF_VERSION} && bazel --output_user_root="${WRKDIR}/.bazel" build --config=opt //tensorflow:libtensorflow.so ${BAZEL_COPT}
	cd ${WRKSRC}/docker/tensorflow/tensorflow-${TF_VERSION} && ./create_archive.sh freebsd-cpu ${TF_VERSION}
	@${REINPLACE_CMD} -e 's|	go build -v ./...|	CGO_CFLAGS="-I${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/include" CGO_LDFLAGS="-L${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib" go build -v ./cmd/... ./internal/... ./pkg/...|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|	scripts/build.sh debug|	CGO_CFLAGS="-I${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/include" CGO_LDFLAGS="-L${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib" scripts/build.sh debug|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|PHOTOPRISM_VERSION=.*|PHOTOPRISM_VERSION=${GH_TAGNAME}|' ${WRKSRC}/scripts/build.sh

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${INSTALL_LIB} ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib/libtensorflow.so ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1.15.2
	${INSTALL_LIB} ${WRKSRC}/docker/tensorflow/tensorflow-$(TF_VERSION)/tmp/lib/libtensorflow_framework.so ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1.15.2
	${LN} -fs libtensorflow_framework.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1
	${LN} -fs libtensorflow.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1
	${LN} -fs libtensorflow_framework.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so
	${LN} -fs libtensorflow.so.1.15.2 ${STAGEDIR}${PREFIX}/lib/libtensorflow.so
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
