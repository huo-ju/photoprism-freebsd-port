# $FreeBSD$

PORTNAME=	photoprism
DISTVERSION=	g20240711
CATEGORIES=	www

MAINTAINER=	huoju@devep.net
COMMENT=	Personal Photo Management Web Service

LICENSE=	AGPLv3

RUN_DEPENDS=  ffmpeg:multimedia/ffmpeg \
	exiftool:graphics/p5-Image-ExifTool \
        libheif>=1.14.2:graphics/libheif \
	vips>=8.10:graphics/vips

LIB_DEPENDS=	libtensorflow.so.1:science/libtensorflow1

EXTRACT_DEPENDS=  ${RUN_DEPENDS} \
	bash:shells/bash \
	git:devel/git \
	gmake:devel/gmake \
	npm:www/npm-node18 \
	wget:ftp/wget:1.21+ \
	pkg-config:devel/pkgconf

BUILD_DEPENDS= ${EXTRACT_DEPENDS} 

USES= gmake go:1.22,modules python:3.6+,build

USE_GITHUB=	yes
GH_ACCOUNT=	photoprism
GH_PROJECT=	photoprism
GH_TAGNAME=     240711-2197af848

USE_RC_SUBR=    photoprism
PHOTOPRISM_DATA_DIR=      /var/db/photoprism
SUB_LIST+=      PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=      pkg-install pkg-message

BUILD_OS!=uname -s
BUILD_DATE!=date -u +%y%m%d
BUILD_ARCH!=uname -m

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-facenet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh
	@${REINPLACE_CMD} -e 's|--node-env=production||g' ${WRKSRC}/frontend/package.json
	@${REINPLACE_CMD} -e 's|	sudo npm install -g npm|	cd frontend \&\& env NODE_ENV=production npm install -D webpack-cli|g' ${WRKSRC}/Makefile
	@(cd ${WRKSRC} ; \
		./scripts/download-facenet.sh ; \
		./scripts/download-nasnet.sh ; \
		./scripts/download-nsfw.sh ; \
	)

pre-build:
	${MKDIR} ${WRKSRC}/build
	${MKDIR} ${WRKSRC}/assets/static/build

	@( cd ${WRKSRC}/frontend; \
		npm install --yes -D webpack-cli@^4.10.0 ; \
	)

do-build:
	@( cd ${WRKSRC}/frontend; \
		env NODE_ENV=production npm run build ; \
		)
	@( cd ${WRKSRC} ; \
		${SETENV} ${MAKE_ENV} ${GO_ENV} ${GO_CMD} build -v -ldflags \
	"-X main.version=${DISTVERSION:C/^...//}-${GH_TAGNAME:C/([0-9a-f]{7}).*/\1/}-${BUILD_OS}-${BUILD_ARCH}-DEBUG-build-${BUILD_DATE}" \
	-o ${WRKSRC}/photoprism ./cmd/photoprism/photoprism.go ; \
		)

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
